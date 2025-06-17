require 'time'
require 'json'
require 'socket'
require 'objspace'
require 'concurrent/atomic/atomic_boolean'
require 'thread'

module HeapPeriscopeAgent
  class Collector
    def self.collect_snapshot(detailed_mode = false)
      data = {
        gc_stats: GC.stat,
        object_space_summary: ObjectSpace.count_objects
      }

      if detailed_mode
        data[:living_objects_by_class] = collect_detailed_living_objects(HeadPeriscopeAgent.configuration.detailed_objects_limit)
      end

      data
    end

    private

    def self.collect_detailed_living_objects(limit)
      counts = Hash.new(0)
      ObjectSpace.each_object do |obj|
        class_name = obj.class.name rescue 'Anonymous/Singleton Class'
        counts[class_name] += 1
      end
      counts.sort_by { |_, count| -count }.first(limit).to_h
    end
  end
end
