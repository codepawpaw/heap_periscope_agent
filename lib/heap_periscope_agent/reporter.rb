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

      log("Reporter starting with interval: #{@config.interval}s.")

      # Enable the standard GC Profiler
      GC::Profiler.enable
      # Store the initial total time to calculate deltas later
      @last_gc_total_time = GC::Profiler.total_time

      @thread = Thread.new do
        @socket = UDPSocket.new
        last_snapshot_time = Time.now

        while @running.true?
          # Periodically send a full snapshot
          if Time.now - last_snapshot_time >= @config.interval
            send_snapshot_report
            last_snapshot_time = Time.now
          end

          # Check for new GC activity since the last check
          send_gc_profiler_report

          sleep(1) # Main loop delay
        end

        log("Reporter loop finished.")
        GC::Profiler.disable # Clean up the profiler
        @socket.close
      end

      @thread.report_on_exception = true
      log("Reporter thread initiated.")
    end

    def self.stop
      return unless @running&.true?

      log("Stopping reporter...")
      @running.make_false
      if @thread&.join(5)
        log("Reporter thread stopped gracefully.")
      else
        log("Reporter thread did not stop in time, killing.", level: :warn)
        @thread&.kill
      end
      @thread = nil
      log("Reporter stop process complete.")
    end

    def self.report_once!
      @config = HeapPeriscopeAgent.configuration
      @socket = UDPSocket.new
      send_snapshot_report
      @socket.close
    end

    private

    def self.send_snapshot_report
      log("Collecting periodic snapshot...")
      stats = HeapPeriscopeAgent.Collector.collect_snapshot(@config.enable_detailed_objects)
      send_payload(stats, "snapshot")
    end

    def self.send_gc_profiler_report
      current_gc_total_time = GC::Profiler.total_time
      # Calculate time spent in GC since our last check
      gc_time_delta = current_gc_total_time - @last_gc_total_time

      # If there was GC activity, report it
      if gc_time_delta > 0
        log("Detected GC activity. Sending GC profiler report.")
        payload = {
          # Convert from seconds to milliseconds
          gc_duration_since_last_check_ms: (gc_time_delta * 1000).round(2),
          gc_invocation_count: GC.count, # Total number of GCs so far
          latest_gc_info: GC.latest_gc_info,
        }
        send_payload(payload, "gc_profiler_report")
        
        # Update the last known time
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
      log("Sent #{type} payload.")
    rescue => e
      log("Failed to send payload: #{e.message}", level: :error)
    end

    def self.log(message, level: :info)
      return unless @config&.verbose
      timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
      output = "[HeapPeriscopeAgent][#{level.to_s.upcase}] #{timestamp}: #{message}"
      level == :error ? warn(output) : puts(output)
    end
  end
end
