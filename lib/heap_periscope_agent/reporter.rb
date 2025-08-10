require 'time'
require 'json'
require 'socket'
require 'objspace'
require 'concurrent/atomic/atomic_fixnum'
require 'thread'

module HeapPeriscopeAgent
  class Reporter
    @lock = Mutex.new
    @active_count = Concurrent::AtomicFixnum.new(0)
    @thread = nil
    @last_gc_total_time = 0
    @span_reports = {}

    def self.start
      @config ||= HeapPeriscopeAgent.configuration

      if @active_count.increment == 1
        @lock.synchronize do
          return if @thread&.alive?

          HeapPeriscopeAgent.log("Reporter starting with interval: #{@config.interval}s.")

          GC::Profiler.enable
          @last_gc_total_time = GC::Profiler.total_time

          @thread = Thread.new do
            @socket = UDPSocket.new
            last_snapshot_time = Time.now

            while @active_count.value > 0
              if Time.now - last_snapshot_time >= @config.interval
                send_snapshot_report
                last_snapshot_time = Time.now
              end

              send_gc_profiler_report

              sleep(1)
            end

            HeapPeriscopeAgent.log("Reporter loop finished.")
            GC::Profiler.disable
            @socket.close
          end

          @thread.report_on_exception = true
          HeapPeriscopeAgent.log("Reporter thread initiated.")
        end
      else
        HeapPeriscopeAgent.log("Reporter already running. Active count: #{@active_count.value}")
      end
    end

    def self.stop
      return if @active_count.value.zero?

      if @active_count.decrement == 0
        @lock.synchronize do
          return unless @active_count.value.zero?

          thread_to_join = @thread
          @thread = nil

          HeapPeriscopeAgent.log("Stopping reporter...")

          if thread_to_join&.join(5)
            HeapPeriscopeAgent.log("Reporter thread stopped gracefully.")
          else
            HeapPeriscopeAgent.log("Reporter thread did not stop in time, killing.", level: :warn)
            thread_to_join&.kill
          end
          HeapPeriscopeAgent.log("Reporter stop process complete.")
        end
      else
        HeapPeriscopeAgent.log("Jobs still active. Active count: #{@active_count.value}")
      end
    end

    def self.report_once!
      @config = HeapPeriscopeAgent.configuration
      @socket = UDPSocket.new
      send_snapshot_report
      @socket.close
    end

    def self.add_span_report(span_type, span_name, objects_data)
      @span_reports[span_type] ||= []
      @span_reports[span_type] << { name: span_name, live_objects: objects_data }
    end

    private

    def self.service_name
      if @config && @config.service_name
        return @config.service_name
      end

      if defined?(::Sidekiq) && ::Sidekiq.server?
        'Sidekiq'
      elsif File.basename($0) == 'rake'
        'Rake'
      elsif defined?(::Rails)
        'Rails'
      else
        File.basename($0)
      end
    end

    def self.send_snapshot_report
      HeapPeriscopeAgent.log("Collecting periodic snapshot...")
      stats = HeapPeriscopeAgent::Collector.collect_snapshot(@config.enable_detailed_objects)

      payload_data = stats.merge(living_objects_by_spans: @span_reports)
      send_payload(payload_data, "snapshot")

      @span_reports = {}
    end

    def self.send_gc_profiler_report
      current_gc_total_time = GC::Profiler.total_time
      gc_time_delta = current_gc_total_time - @last_gc_total_time

      if gc_time_delta > 0
        HeapPeriscopeAgent.log("Detected GC activity. Sending GC profiler report.")
        payload = {
          gc_duration_since_last_check_ms: (gc_time_delta * 1000).round(2),
          latest_gc_info: GC.latest_gc_info,
        }
        send_payload(payload, "gc_profiler_report")
        
        @last_gc_total_time = current_gc_total_time
      end
    end

    def self.send_payload(data, type)
      payload = {
        type: type,
        process_id: Process.pid,
        service_name: self.service_name,
        reported_at: Time.now.utc.iso8601,
        payload: data
      }.to_json

      @socket.send(payload, 0, @config.host, @config.port)
      HeapPeriscopeAgent.log("Sent #{type} payload.")
    rescue => e
      HeapPeriscopeAgent.log("Failed to send payload: #{e.message}", level: :error)
    end
  end
end
