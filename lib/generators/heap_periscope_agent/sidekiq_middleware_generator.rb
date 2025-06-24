require 'rails/generators/base'

module HeapPeriscopeAgent
  module Generators
    class SidekiqMiddlewareGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_sidekiq_initializer
        template "heap_periscope_agent_sidekiq.rb.tt", "config/initializers/heap_periscope_agent_sidekiq.rb"
        puts "\nHeapPeriscopeAgent Sidekiq middleware created at config/initializers/heap_periscope_agent_sidekiq.rb"
        puts "This will track all Sidekiq jobs. Please restart your Sidekiq server for changes to take effect."
      end
    end
  end
end