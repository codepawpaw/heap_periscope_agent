# Heap Periscope Agent

[![Gem Version](https://badge.fury.io/rb/heap_periscope_agent.svg)](https://badge.fury.io/rb/heap_periscope_agent) <!-- Placeholder: update if you publish to RubyGems -->
<!-- Add other badges if you have CI/CD, code coverage, etc. -->

**Heap Periscope Agent** is a lightweight, configurable Ruby gem designed to provide developers with deep insights into their application's memory behavior. It focuses on real-time collection and reporting of crucial Garbage Collection (GC) statistics and object allocation patterns. By offering granular data, it empowers developers to proactively identify potential memory leaks, optimize memory usage, and fine-tune application performance related to heap management.

## Features

*   **Real-time Metrics:** Collects GC and object allocation data as your application runs.
*   **Configurable:** Easily adjust collection interval, reporting endpoint, and data verbosity.
*   **Detailed Object Insights:** Optionally track specific object allocations for deeper analysis.
*   **Lightweight:** Designed to have minimal impact on your application's performance.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'heap_periscope_agent'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install heap_periscope_agent
```

## Usage

### Configuration

You can configure Heap Periscope Agent, typically in an initializer file (e.g., `config/initializers/heap_periscope_agent.rb` in a Rails application) or early in your application's boot process.

```ruby
HeapPeriscopeAgent.configure do |config|
  # Interval in seconds for collecting and reporting metrics.
  config.interval = 10 # Default: 10

  # Host of the server where metrics will be sent.
  config.host = '127.0.0.1' # Default: '127.0.0.1'

  # Port of the metrics server.
  config.port = 9000 # Default: 9000

  # Enable verbose logging from the agent.
  config.verbose = true # Default: true

  # Enable collection of detailed object allocation information.
  # This can have a higher performance overhead.
  config.enable_detailed_objects = false # Default: false

  # If detailed_objects is enabled, this limits the number of
  # distinct object types to report on.
  config.detailed_objects_limit = 20 # Default: 20
end
```

### Starting the Agent

To start collecting and reporting metrics, you'll need to initialize and run the agent's collector and reporter. (Further implementation details for starting the agent, such as a `HeapPeriscopeAgent.start` method, would typically be added to the gem itself).

A conceptual `HeapPeriscopeAgent.start` method would likely:
1. Initialize `HeapPeriscopeAgent::Collector` with the current configuration.
2. Initialize `HeapPeriscopeAgent::Reporter` with the current configuration.
3. Periodically trigger the collector to gather data and the reporter to send it, based on the configured `interval`. This might run in a separate thread.

```ruby
# Example: In your application's startup sequence
# This is a conceptual example; you'll need to implement the start logic
# or integrate the Collector and Reporter manually.

# if defined?(HeapPeriscopeAgent.start)
#   HeapPeriscopeAgent.start
# else
#   # Manual setup might look something like this (highly simplified):
#   # Thread.new do
#   #   loop do
#   #     collector = HeapPeriscopeAgent::Collector.new(HeapPeriscopeAgent.configuration)
#   #     reporter = HeapPeriscopeAgent::Reporter.new(HeapPeriscopeAgent.configuration)
#   #     data = collector.collect_data
#   #     reporter.report(data)
#   #     sleep HeapPeriscopeAgent.configuration.interval
#   #   end
#   # end
# end
```

### Configuration Options

| Option                    | Description                                                                 | Default     |
|---------------------------|-----------------------------------------------------------------------------|-------------|
| `interval`                | Data collection and reporting interval in seconds.                          | `10`        |
| `host`                    | Hostname/IP of the metrics collection server.                               | `'127.0.0.1'` |
| `port`                    | Port of the metrics collection server.                                      | `9000`      |
| `verbose`                 | Enable verbose logging from the agent.                                      | `true`      |
| `enable_detailed_objects` | Enable collection of detailed object allocation information.                | `false`     |
| `detailed_objects_limit`  | Max number of detailed object types to report if `enable_detailed_objects` is true. | `20`        |

## Development

After checking out the repo, run `bin/setup` to install dependencies (if you have such a script, otherwise `bundle install`).

To build the gem locally:

```bash
gem build heap_periscope_agent.gemspec
```

To install this gem onto your local machine:

```bash
gem install ./heap_periscope_agent-0.0.0.gem # Replace with the actual version built
```

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/your_username/heap_periscope_agent. <!-- TODO: Update this URL -->
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the Contributor Covenant code of conduct. <!-- Optional: if you adopt one -->

1.  Fork the repository.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create a new Pull Request.

