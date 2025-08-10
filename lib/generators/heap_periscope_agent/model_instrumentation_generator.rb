require 'rails/generators/base'

module HeapPeriscopeAgent
  module Generators
    class ModelInstrumentationGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_model_initializer
        template "heap_periscope_agent_model.rb.tt", "config/initializers/heap_periscope_agent_model.rb"
        puts "\nHeapPeriscopeAgent model instrumentation created at config/initializers/heap_periscope_agent_model.rb"
        puts "This will track living objects after each model create, update, and destroy."
        puts "Remember to enable `config.enable_model_instrumentation = true` in your main HeapPeriscopeAgent initializer."
      end
    end
  end
end