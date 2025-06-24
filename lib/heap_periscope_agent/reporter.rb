require 'time'
require 'json'
require 'socket'
require 'objspace'
require 'concurrent/atomic/atomic_boolean'
require 'thread'

module HeapPeriscopeAgent
  class Reporter
    def self.start
      @config = HeapPeriscopeAgent.configuration
      @running = Concurrent::AtomicBoolean.new(false)

      return if @running.true?
      @running.make_true

      HeapPeriscopeAgent.log("Reporter starting with interval: #{@config.interval}s.")

      GC::Profiler.enable
      @last_gc_total_time = GC::Profiler.total_time

      @thread = Thread.new do
        @socket = UDPSocket.new
        last_snapshot_time = Time.now

        while @running.true?
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

    def self.stop
      return unless @running&.true?

      HeapPeriscopeAgent.log("Stopping reporter...")
      @running.make_false
      if @thread&.join(5)
        HeapPeriscopeAgent.log("Reporter thread stopped gracefully.")
      else
        HeapPeriscopeAgent.log("Reporter thread did not stop in time, killing.", level: :warn)
        @thread&.kill
      end
      @thread = nil
      HeapPeriscopeAgent.log("Reporter stop process complete.")
    end

    def self.report_once!
      @config = HeapPeriscopeAgent.configuration
      @socket = UDPSocket.new
      send_snapshot_report
      @socket.close
    end

    private

    def self.send_snapshot_report
      HeapPeriscopeAgent.log("Collecting periodic snapshot...")
      stats = HeapPeriscopeAgent::Collector.collect_snapshot(@config.enable_detailed_objects)
      send_payload(stats, "snapshot")
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
