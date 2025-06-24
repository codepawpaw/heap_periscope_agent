require 'rails/generators/base'

module HeapPeriscopeAgent
  module Generators
    class ConfigGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_initializer_file
        copy_file "heap_periscope_agent.rb.tt", "config/initializers/heap_periscope_agent.rb"
        puts "\nHeapPeriscopeAgent initializer created at config/initializers/heap_periscope_agent.rb"
        puts "Please review and customize the configuration as needed for your environment."
      end
    end
  end
end