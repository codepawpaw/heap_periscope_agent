require 'rails/generators/base'

module HeapPeriscopeAgent
  module Generators
    class ControllerInstrumentationGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_controller_initializer
        template "heap_periscope_agent_controller.rb.tt", "config/initializers/heap_periscope_agent_controller.rb"
        puts "\nHeapPeriscopeAgent controller instrumentation created at config/initializers/heap_periscope_agent_controller.rb"
        puts "This will track living objects after each controller action."
        puts "Remember to enable `config.enable_controller_instrumentation = true` in your main HeapPeriscopeAgent initializer."
      end
    end
  end
end