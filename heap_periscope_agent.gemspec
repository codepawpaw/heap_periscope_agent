require_relative "lib/heap_periscope_agent/version"

Gem::Specification.new do |s|
    s.name        = "heap_periscope_agent"
    s.version     = HeapPeriscopeAgent::VERSION
    s.summary     = "Monitors Ruby application memory with real-time GC and object allocation metrics."
    s.description = <<~DESC
      Heap Periscope Agent offers deep insights into your Ruby application's memory behavior.
      It collects and reports real-time Garbage Collection (GC) statistics and object
      allocation patterns, empowering developers to identify memory leaks, optimize usage,
      and enhance performance. This gem is the backend agent for memory monitoring. To
      visualize the collected data, you must also install the companion gem,
      heap_periscope_ui

      The agent's visualizer is available here:
      - Gem: https://rubygems.org/gems/heap_periscope_ui
      - Repository: https://github.com/codepawpaw/heap_periscope_ui
    DESC
    s.authors     = ["Jonathan Natanael Siahaan"]
    s.email       = "js.jonathan.n@gmail.com"
    s.files       = Dir.glob("lib/**/*.rb") + Dir.glob("lib/generators/**/*")
    s.homepage    = "https://github.com/codepawpaw/heap_periscope_agent"
    s.license     = "MIT"
    s.metadata["homepage_uri"] = s.homepage
    s.metadata["source_code_uri"] = s.homepage
    s.metadata["changelog_uri"] = "https://github.com/codepawpaw/heap_periscope_agent/blob/master/CHANGELOG.md"
    s.metadata["bug_tracker_uri"] = "https://github.com/codepawpaw/heap_periscope_agent/issues"
end