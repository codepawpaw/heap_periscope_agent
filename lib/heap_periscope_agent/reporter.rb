require 'time'
require 'json'
require 'socket'
require 'objspace'
require 'concurrent/atomic/atomic_fixnum'
require 'thread'

module HeapPeriscopeAgent
  class Reporter
    # Using a lock to synchronize thread creation/destruction
    @lock = Mutex.new
    # Using a reference counter for concurrent start/stop calls (e.g., in Sidekiq)
    @active_count = Concurrent::AtomicFixnum.new(0)
    @thread = nil
    @last_gc_total_time = 0

    def self.start
      @config ||= HeapPeriscopeAgent.configuration

      # If we increment from 0 to 1, we are responsible for starting the thread.
      if @active_count.increment == 1
        @lock.synchronize do
          # In case of a race condition, ensure thread is not already running.
          return if @thread&.alive?

          HeapPeriscopeAgent.log("Reporter starting with interval: #{@config.interval}s.")

          GC::Profiler.enable
          @last_gc_total_time = GC::Profiler.total_time

          @thread = Thread.new do
            @socket = UDPSocket.new
            last_snapshot_time = Time.now

            # The loop continues as long as there are active jobs.
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

      # If we decrement from 1 to 0, we are responsible for stopping the thread.
      if @active_count.decrement == 0
        @lock.synchronize do
          # Check again in case a `start` call incremented the counter while we waited for the lock.
          return unless @active_count.value.zero?

          thread_to_join = @thread
          @thread = nil # Allow a new thread to be created on next `start`

          HeapPeriscopeAgent.log("Stopping reporter...")
          # The thread's loop condition (`@active_count.value > 0`) is now false,
          # so it should exit gracefully. We join to wait for it.
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
