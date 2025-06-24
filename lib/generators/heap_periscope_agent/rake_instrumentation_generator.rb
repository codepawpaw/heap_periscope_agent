require 'rails/generators/base'

module HeapPeriscopeAgent
  module Generators
    class RakeInstrumentationGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_rake_initializer
        template "heap_periscope_agent_rake.rb.tt", "config/initializers/heap_periscope_agent_rake.rb"
        puts "\nHeapPeriscopeAgent Rake instrumentation created at config/initializers/heap_periscope_agent_rake.rb"
        puts "This will track all Rake tasks invoked from the command line."
      end
    end
  end
end