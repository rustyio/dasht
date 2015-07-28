class Array
  def sum; self.compact.inject(:+); end
end

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

    def add_line(line)
      @line_queue.push(line)
    end

    def add_event_definition(metric, regex, op, value, block)
      @event_definitions << [metric, regex, op, value, block]
    end

    def reset_event_definitions
      @event_definitions = []
    end

    def set(metric, value, op = :last, time = Time.now)
      @metric_operations[metric] = op
      m = (@metric_values[metric] ||= Metric.new)
      m.append(value, time) do |old_value, new_value|
        old_value.nil? ? new_value : [old_value, new_value].send(op)
      end
      print "#{metric} - #{m.to_s}\n"
    end

    def get(metric, resolution = 60, time = Time.now)
      m = @metric_values[metric]
      return 0 if m.nil?
      op = @metric_operations[metric]
      print "Metric: #{metric}\n"
      print "Operation: #{op}\n"
      print "Data: #{m.enum(time.to_i - resolution).to_a}\n"
      m.enum(time.to_i - resolution).to_a.flatten.send(op)
    end

    def run
      Thread.new do
        begin
          while line = @line_queue.pop
            @total_lines += 1
            @total_bytes += line.length
            print "\rConsumed #{@total_lines} lines (#{@total_bytes} bytes)..."
            _consume_line(line)
          end
        rescue => e
          parent.log "Error processing metric #{metric}"
          parent.log "  Regex: #{regex}"
          parent.log "  Line: #{line}"
          parent.log "#{e}\n#{e.backtrace.join('\n')}\n"
        end
      end
    end

    private

    def _consume_line(line)
      @event_definitions.each do |metric, regex, op, value, block|
        begin
          regex.match(line) do |matches|
            if block
              value = block.call(matches)
            end
            print "Setting #{metric} - #{value} - #{op}\n"
            set(metric, value, op) if value
          end
        rescue => e
          parent.log "Error processing metric #{metric}"
          parent.log "  Regex: #{regex}"
          parent.log "  Line: #{line}"
          parent.log "#{e}\n#{e.backtrace.join('\n')}\n"
        end
      end
    end
  end
end
