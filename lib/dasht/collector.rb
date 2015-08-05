module Dasht
  class Metrics
    attr_accessor :parent
    def initialize(parent)
      @parent            = parent
      @metric_values     = {}
      @metric_operations = {}
    end

    def set(metric, value, op, ts)
      metric = metric.to_s
      @metric_operations[metric] = op
      m = (@metric_values[metric] ||= Metric.new)
      m.append(value, ts) do |old_value, new_value|
        [old_value, new_value].compact.flatten.send(op)
      end
    end

    def get(metric, start_ts, end_ts)
      metric = metric.to_s
      m = @metric_values[metric]
      return [] if m.nil?
      op = @metric_operations[metric]
      m.enum(start_ts, end_ts).to_a.flatten.send(op)
    end

    def trim_to(ts)
      @metric_values.each do |k, v|
        v.trim_to(ts)
      end
    end
  end
end
