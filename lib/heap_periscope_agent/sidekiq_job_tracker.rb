module HeapPeriscopeAgent
    # A module to be prepended to a Sidekiq job class to track its memory usage
    # during its `perform` execution.
    module SidekiqJobTracker
      def perform(*args)
        HeapPeriscopeAgent.log("Starting agent for #{self.class.name}...")
        HeapPeriscopeAgent.start
        super
      ensure
        HeapPeriscopeAgent.log("Stopping agent for #{self.class.name}.")
        HeapPeriscopeAgent.stop
      end
    end
end