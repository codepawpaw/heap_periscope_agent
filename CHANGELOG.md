# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0] - Unreleased

### Added
- Rails generator to instrument all Rake tasks (`heap_periscope_agent:rake_instrumentation`).
- Rails generator to track a specific Rake task (`heap_periscope_agent:rake_task_tracker`).
- Rails generator to install Sidekiq middleware for tracking all jobs (`heap_periscope_agent:sidekiq_middleware`).
- Rails generator to instrument a single Sidekiq job for tracking (`heap_periscope_agent:job_tracker`).
- Concurrency-safe `Reporter` to handle multiple jobs in the same process.
- Documentation for manual, Sidekiq, and Rake usage.

## [0.1.0] - 2025-06-17

### Added
- Initial release of Heap Periscope Agent.
- Core functionality for collecting and reporting GC and object allocation metrics.
- Configuration options for interval, host, port, verbosity, and detailed object tracking.