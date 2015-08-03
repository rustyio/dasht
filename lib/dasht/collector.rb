module Dasht
  class Collector
    attr_accessor :parent
    def initialize(parent)
      @parent            = parent
      @metric_values     = {}
      @metric_operations = {}
      @event_definitions = []
      @total_lines       = 0
      @total_bytes       = 0
      @line_queue        = Queue.new
    end

    def add_line(ts, line)
      @line_queue.push([ts, line])
    end

    def add_event_definition(metric, regex, op, value, block)
      @event_definitions << [metric, regex, op, value, block]
    end

    def reset_event_definitions
      @event_definitions = []
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

    def run
      Thread.new do
        begin
          while true
            ts, line = @line_queue.pop
            @total_lines += 1
            @total_bytes += line.length
            print "\rConsumed #{@total_lines} lines (#{@total_bytes} bytes)..."
            _consume_line(ts, line)
          end
        rescue => e
          parent.log e
          raise e
        end
      end
    end

    private

    def _consume_line(ts, line)
      @event_definitions.each do |metric, regex, op, value, block|
        begin
          regex.match(line) do |matches|
            value = matches[0] if value.nil?
            value = block.call(matches) if block
            set(metric, value, op, ts) if value
          end
        rescue => e
          parent.log e
          raise e
        end
      end
    end
  end
end
