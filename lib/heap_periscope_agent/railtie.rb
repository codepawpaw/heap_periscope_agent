require 'heap_periscope_agent' # Ensure the main module is loaded

module HeapPeriscopeAgent
  class Railtie < Rails::Railtie
    initializer "heap_periscope_agent.start_agent", after: :load_config_initializers do |app|
      HeapPeriscopeAgent.log("Rails Initializer: Starting HeapPeriscopeAgent...")
      HeapPeriscopeAgent.start
    end
  end
end