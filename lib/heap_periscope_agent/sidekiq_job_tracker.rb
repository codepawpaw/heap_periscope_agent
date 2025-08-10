module HeapPeriscopeAgent
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