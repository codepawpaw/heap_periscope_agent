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

### Agent Setup

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

### UI Setup
To get a complete, end-to-end view of your application's memory usage, you'll need to run both the Heap Periscope Agent and the Heap Periscope UI. The agent collects the data, and the UI visualizes it

You can find the Heap Periscope UI here: 
https://github.com/codepawpaw/heap_periscope_ui

Add this line to your application's Gemfile:

```ruby
gem 'heap_periscope_ui'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install heap_periscope_ui
```

## Usage

### 1. Installation & Setup

For Rails applications, after bundling the gem, run the config generator to create an initializer file:

```bash
rails generate heap_periscope_agent:config
```
This will create `config/initializers/heap_periscope_agent.rb`.

```ruby
# config/initializers/heap_periscope_agent.rb
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

### 2. Tracking Rails Controller Living Objects

If you want to monitor living objects inside rails controller, you can generate a specific tracker for it.

```bash
rails generate heap_periscope_agent:controller_instrumentation
```

Remember to enable `config.enable_controller_instrumentation = true` in your main HeapPeriscopeAgent initializer

### 3. Tracking Rails Model Living Objects

If you want to monitor living objects inside rails model, you can generate a specific tracker for it.

```bash
rails generate heap_periscope_agent:model_instrumentation
```

Remember to enable `config.enable_model_instrumentation = true` in your main HeapPeriscopeAgent initializer

### 3. Tracking Sidekiq Jobs

The agent can be easily configured to monitor the memory usage of your Sidekiq jobs.

#### Tracking All Sidekiq Jobs

To monitor every job processed by your Sidekiq server, you can install a middleware. This is the recommended approach for general monitoring.

```bash
rails generate heap_periscope_agent:sidekiq_middleware
```

This command creates an initializer that adds the tracking middleware to Sidekiq's server chain. Restart your Sidekiq process for the change to take effect.

#### Tracking a Specific Sidekiq Job

If you need to focus on a single, potentially problematic job, you can instrument it directly.

```bash
rails generate heap_periscope_agent:job_tracker MySpecificJob
```

Replace `MySpecificJob` with the class name of your job (e.g., `ProcessCsvJob`, `Integrations::ThirdPartySyncJob`). This will prepend a tracking module directly into the job file.

### 4. Tracking Rake Tasks

The agent can also monitor the memory usage of your Rake tasks.

#### Tracking All Rake Tasks

To monitor the entire execution of any Rake command (e.g., `rails db:migrate`, `rails assets:precompile`), you can install the Rake instrumentation. This is the recommended approach for general monitoring of background tasks.

```bash
rails generate heap_periscope_agent:rake_instrumentation
```

This command creates an initializer that wraps the main Rake execution loop, starting the agent when the command begins and stopping it when it finishes.

#### Tracking a Specific Rake Task

If you want to isolate and monitor a single Rake task, you can generate a specific tracker for it.

```bash
rails generate heap_periscope_agent:rake_task_tracker my_namespace:my_task
```

Replace `my_namespace:my_task` with the name of your task. This command will create a new file in `lib/tasks/` that enhances your existing task at runtime to add memory profiling. This method does not modify your original Rake file.

### 5. Manual Usage

Beyond the automated setup for Rails and Sidekiq, you can control the agent programmatically. This is useful for profiling specific sections of code, Rake tasks, or in non-Rails applications.

### 6. Visit the result
Open http://localhost:3000/heap_periscope in your browser

#### Wrapping a Code Block

To monitor a specific piece of code, you can wrap it with `HeapPeriscopeAgent.start` and `HeapPeriscopeAgent.stop`. It's crucial to use an `ensure` block to guarantee that the agent is stopped, even if an error occurs.

```ruby
begin
  HeapPeriscopeAgent.start
  # --- Your code to be profiled goes here ---
ensure
  HeapPeriscopeAgent.stop
end
```

#### Taking a Single Snapshot

If you don't need continuous monitoring and just want a single, on-demand snapshot of the application's memory state, you can use `report_once!`. This will collect and send a single report without starting the background monitoring thread.

```ruby
HeapPeriscopeAgent.report_once!
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
| `enable_controller_instrumentation` | Enable tracking of living objects after each Rails controller action. | `false`     |
| `service_name`            | An optional custom name for the service/process. If not set, it's automatically detected (Rails, Sidekiq, Rake). | `nil` (auto-detected) |

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

Bug reports and pull requests are welcome on GitHub at https://github.com/codepawpaw/heap_periscope_agent.
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the Contributor Covenant code of conduct. <!-- Optional: if you adopt one -->

1.  Fork the repository.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create a new Pull Request.
