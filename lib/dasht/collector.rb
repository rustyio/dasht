module Dasht
  class Collector
    def initialize
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

    def set(metric, value, op = :last)
      metric = metric.to_s
      secs = Time.now.to_i
      @metric_operations[metric] = op
      @metric_values[metric] ||= {}
      @metric_values[metric][secs] =
        if @metric_values[metric][secs].nil?
          value
        else
          [@metric_values[metric][secs], value].send(op)
        end
    end

    def get(metric, resolution = 60)
      metric = metric.to_s
      return 0 if @metric_values[metric].nil?
      secs = Time.now.to_i
      values = ((secs - resolution)..secs).map do |n|
        @metric_values[metric][n]
      end.compact.flatten.send(@metric_operations[metric])
    end

    def run
      Thread.new do
        while line = @line_queue.pop
          @total_lines += 1
          @total_bytes += line.length
          print "\rConsumed #{@total_lines} lines (#{@total_bytes} bytes)..."
          _consume_line(line)
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
            set(metric, value, op) if value
          end
        rescue => e
          dasht.log "Error processing metric #{metric}"
          dasht.log "  Regex: #{regex}"
          dasht.log "  Line: #{line}"
          dasht.log "#{e}\n#{e.backtrace.join('\n')}\n"
        end
      end
    end
  end
end
