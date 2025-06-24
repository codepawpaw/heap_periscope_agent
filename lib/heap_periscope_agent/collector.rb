require 'objspace'

module HeapPeriscopeAgent
  class Collector
    # Identifiers for common platform classes (Ruby core and Rails framework).
    # Namespaces should end with '::' for prefix matching.
    # Exact class names are matched directly.
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
        data[:living_objects_by_class] = collect_detailed_living_objects(HeapPeriscopeAgent.configuration.detailed_objects_limit) do |obj|
          begin
            # Attempt to get the class of the object
            obj_class = obj.class
            name = obj_class.name
            # Use class.inspect for anonymous classes (where name is nil/empty), otherwise use class.name
            (name.nil? || name.empty?) ? obj_class.inspect : name
          rescue NoMethodError # Handles BasicObject where .class (and thus .name) is not defined
            # BasicObject instances typically have .inspect
            obj.inspect rescue 'Uninspectable BasicObject'
          rescue => e # Catch any other unexpected error during class/name retrieval for safety
            "ErrorGettingClassName: #{e.class}" # Provide some context for the error
          end
        end
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

    private

    # Collects detailed living objects, allowing a block to customize the key used for counting.
    # The block receives the object and should return a string key.
    # Objects that do not respond to `class` (like instances of BasicObject) are handled
    # by the default key_proc or the provided block.
    def self.collect_detailed_living_objects(limit, &key_proc)
      # Default fallback: try class.name, then class.inspect, then obj.inspect, finally a generic string
      key_proc ||= lambda do |obj|
        begin
          obj_class = obj.class
          name = obj_class.name
          (name.nil? || name.empty?) ? obj_class.inspect : name
        rescue NoMethodError # For BasicObject
          obj.inspect rescue 'Uninspectable BasicObject (default proc)'
        rescue => e # Other errors
          "ErrorInDefaultProc: #{e.class}"
        end
      end

      # The counts hash will now store:
      # { class_name_key => { count: N, is_platform_class: true/false } }
      object_details = Hash.new

      ObjectSpace.each_object do |obj|
        begin
          class_name_key = key_proc.call(obj)
          unless object_details.key?(class_name_key)
            object_details[class_name_key] = { count: 0, is_platform_class: is_platform_class?(class_name_key) }
          end
          object_details[class_name_key][:count] += 1
        rescue
          object_details['Error Collecting Class Name'] ||= { count: 0, is_platform_class: false }
          object_details['Error Collecting Class Name'][:count] += 1
        end
      end
      object_details.sort_by { |_, data| -data[:count] }.first(limit).to_h
    end
  end
end
