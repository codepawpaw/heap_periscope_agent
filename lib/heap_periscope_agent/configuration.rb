module HeapPeriscopeAgent
  class Configuration
    attr_accessor :interval, :host, :port, :verbose, :enable_detailed_objects, :detailed_objects_limit

    def initialize
      @interval = 10 # seconds
      @host = '127.0.0.1'
      @port = 9000
      @verbose = true
      @enable_detailed_objects = false
      @detailed_objects_limit = 20
    end
  end
end
