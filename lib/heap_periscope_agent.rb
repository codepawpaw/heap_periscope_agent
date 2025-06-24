require_relative "heap_periscope_agent/version"
require_relative "heap_periscope_agent/configuration"
require_relative "heap_periscope_agent/collector"
require_relative "heap_periscope_agent/reporter"

module HeapPeriscopeAgent
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def start
      log("HeapPeriscopeAgent starting...")
      Reporter.start
      log("HeapPeriscopeAgent started successfully.")
    rescue => e
      log("Failed to start HeapPeriscopeAgent: #{e.message} #{e.backtrace.join("\n")}", level: :error)
    end

    def stop
      log("HeapPeriscopeAgent stopping...")
      Reporter.stop
      log("HeapPeriscopeAgent stopped.")
    rescue => e
      log("Failed to stop HeapPeriscopeAgent: #{e.message}", level: :error)
    end

    def report_once!
      Reporter.report_once!
    end

    def log(message, level: :info)
      return unless configuration&.verbose
      timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
      output = "[HeapPeriscopeAgent][#{level.to_s.upcase}] #{timestamp}: #{message}"
      if level == :error || level == :warn
        Kernel.warn(output)
      else
        Kernel.puts(output)
      end
    end
  end

  if defined?(Rails::Railtie)
    require_relative "heap_periscope_agent/railtie"
  end
end