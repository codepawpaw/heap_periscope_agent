require 'rails/generators/base'

module HeapPeriscopeAgent
  module Generators
    class RakeTaskTrackerGenerator < Rails::Generators::Base
      argument :task_name, type: :string, desc: "The name of the Rake task to track (e.g. my_namespace:my_task)"

      def add_rake_tracker
        rakefile_path = "lib/tasks/zzz_heap_periscope_agent_trackers.rake"

        # Create the file with a header if it doesn't exist
        unless File.exist?(rakefile_path)
          create_file rakefile_path, "# This file is for auto-generated Rake task trackers for HeapPeriscopeAgent.\n# It is named with a 'zzz_' prefix to ensure it loads after other tasks are defined.\n\n"
        end

        tracker_code = <<~RUBY
          # --- Tracker for #{task_name} task ---
          if Rake::Task.task_defined?('#{task_name}')
            task_to_track = Rake::Task['#{task_name}']
            original_actions = task_to_track.actions.dup
            task_to_track.clear_actions

            task_to_track.enhance do |t, args|
              begin
                require 'heap_periscope_agent' # Ensure agent is loaded and configured
                HeapPeriscopeAgent.log("Starting agent for Rake task: #{t.name}")
                HeapPeriscopeAgent.start
                original_actions.each { |action| action.call(t, args) } # Execute original task
              ensure
                HeapPeriscopeAgent.log("Stopping agent for Rake task: #{t.name}")
                HeapPeriscopeAgent.stop
              end
            end
          end
        RUBY

        append_to_file(rakefile_path, "\n#{tracker_code}\n")
        say "Added tracker for Rake task '#{task_name}' in #{rakefile_path}", :green
        say "NOTE: This method relies on this file being loaded *after* the task is defined. The 'zzz_' prefix helps, but is not a guarantee.", :yellow
      end
    end
  end
end