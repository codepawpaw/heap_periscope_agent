require 'objspace'

module HeapPeriscopeAgent
  class Collector
    PLATFORM_CLASS_IDENTIFIERS = [
      # Ruby Core Classes
      "String",
      "Array",
      "Hash",
      "Integer",
      "Float",
      "Symbol",
      "Regexp",
      "Time",
      "Proc",
      "Thread",
      "Range",
      "Set",
      "Enumerator",
      "TrueClass",
      "FalseClass",
      "NilClass",
      # Rails Framework Namespaces
      "ActiveRecord::",
      "ActiveSupport::",
      "ActionView::",
      "ActionController::",
      "ActionDispatch::",
      "ActionMailer::",
      "ActiveJob::",
      "ActiveModel::",
      "Rails::",
      "Sprockets::" # Often included with Rails asset pipeline
    ].freeze

    def self.collect_snapshot(detailed_mode = false)
      data = {
        gc_stats: GC.stat,
        object_space_summary: ObjectSpace.count_objects
      }

      if detailed_mode
        data[:living_objects_by_class] = collect_detailed_living_objects(HeapPeriscopeAgent.configuration.detailed_objects_limit)
      end

      data
    end

    def self.is_platform_class?(class_name_str)
      return false if class_name_str.nil? || class_name_str.empty?
      PLATFORM_CLASS_IDENTIFIERS.any? do |identifier|
        if identifier.end_with?("::")
          class_name_str.start_with?(identifier)
        else
          class_name_str == identifier
        end
      end
    end

    def self.human_readable_bytes(bytes)
      units = ['B', 'KB', 'MB', 'GB', 'TB']
      return '0 B' if bytes == 0
      i = (Math.log(bytes) / Math.log(1024)).floor
      i = [i, units.length - 1].min
      "#{'%.2f' % (bytes.to_f / (1024 ** i))} #{units[i]}"
    end

    def self.collect_detailed_living_objects_for_span(limit)
      raw_data = _collect_raw_object_data

      # Convert raw_data to the desired array format for spans
      # [{ name: "String", type: "native", count: 10, size: "100KB" }, ...]
      sorted_data = raw_data.sort_by { |_, data| -data[:count] }.first(limit)

      sorted_data.map do |class_name, data|
        {
          name: class_name,
          type: is_platform_class?(class_name) ? 'native' : 'application',
          count: data[:count],
          size: human_readable_bytes(data[:total_size])
        }
      end
    end

    private

    def self._collect_raw_object_data
      raw_data = Hash.new do |h, k|
        h[k] = { count: 0, total_size: 0 }
      end

      ObjectSpace.each_object do |obj|
        begin
          # Get class name
          obj_class = obj.class
          class_name = obj_class.name
          class_name = obj_class.inspect if class_name.nil? || class_name.empty?

          raw_data[class_name][:count] += 1

          # Attempt to get object size.
          begin
            size = ObjectSpace.memsize_of(obj)
            raw_data[class_name][:total_size] += size
          rescue TypeError, NoMethodError
            # Ignore objects that don't have a measurable size (e.g., immediates, BasicObject)
          rescue => e
            HeapPeriscopeAgent.log("Error getting memsize_of for #{class_name}: #{e.message}", level: :warn)
          end
        rescue NoMethodError # Handles BasicObject where .class is not defined
          class_name = obj.inspect rescue 'Uninspectable BasicObject'
          raw_data[class_name][:count] += 1
        rescue => e
          error_key = 'Error Collecting Object Data'
          raw_data[error_key][:count] += 1
          HeapPeriscopeAgent.log("Error during object iteration: #{e.message}", level: :warn)
        end
      end
      raw_data
    end

    # Collects detailed living objects for the main snapshot report.
    # This method is kept for the `living_objects_by_class` part of the payload.
    def self.collect_detailed_living_objects(limit)
      raw_data = _collect_raw_object_data

      formatted_data = raw_data.map do |class_name, data|
        [class_name, { count: data[:count], is_platform_class: is_platform_class?(class_name) }]
      end.to_h

      formatted_data.sort_by { |_, data| -data[:count] }.first(limit).to_h
    end
  end
end
