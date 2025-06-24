require 'rails/generators/base'
require 'active_support/core_ext/string/inflections'

module HeapPeriscopeAgent
  module Generators
    class JobTrackerGenerator < Rails::Generators::Base
      argument :job_class_name, type: :string, desc: "The name of the Sidekiq job class to track (e.g. MyJob or MyModule::MyJob)"

      def add_tracker_to_job
        job_file_path = find_job_file
        if job_file_path && File.exist?(job_file_path)
          # Ensure the tracker module is required.
          insert_into_file job_file_path, "require 'heap_periscope_agent/sidekiq_job_tracker'\n\n", before: /class|module/

          # Prepend the tracker module to the class.
          inject_into_class job_file_path, job_class_name, "  prepend HeapPeriscopeAgent::SidekiqJobTracker\n"
          say "Added HeapPeriscopeAgent::SidekiqJobTracker to #{job_class_name} in #{job_file_path}", :green
        else
          say "Could not find job file for '#{job_class_name}'. Expected at '#{job_file_path}'.", :red
        end
      end

      private

      def find_job_file
        File.join("app", "jobs", "#{job_class_name.underscore}.rb")
      end
    end
  end
end
