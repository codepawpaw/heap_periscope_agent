require_relative './heap_periscope_agent/configuration.rb'
require_relative './heap_periscope_agent/collector.rb'
require_relative './heap_periscope_agent/reporter.rb'

module HeapPeriscopeAgent
  def self.configuration
    @configuration ||= HeapPeriscopeAgent::Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
