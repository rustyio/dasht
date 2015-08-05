module Dasht
  class LogThread
    attr_accessor :parent

    def self.update_global_stats(line)
      @total_lines ||= 0
      @total_bytes ||= 0
      @total_lines += 1
      @total_bytes += line.length
      print "\rConsumed #{@total_lines} lines (#{@total_bytes} bytes)..."
    end

    def initialize(parent, command)
      @parent            = parent
      @command           = command
      @event_definitions = []
    end

    def run
      parent.log "Starting `#{@command}`..."
      @thread = Thread.new do
        begin
          while true
            begin
              IO.popen(@command) do |process|
                process.each do |line|
                  _consume_line(line)
                end
              end
            rescue => e
              parent.log e
            end
            sleep 2
          end
        rescue => e
          parent.log e
          raise e
        end
      end
    end

    def event(metric, regex, op, value = nil, &block)
      @event_definitions << [metric, regex, op, value, block]
    end

    def count(metric, regex, &block)
      event(metric, regex, :dasht_sum, 1, &block)
    end

    def gauge(metric, regex, &block)
      event(metric, regex, :last, nil, &block)
    end

    def min(metric, regex, &block)
      event(metric, regex, :min, nil, &block)
    end

    def max(metric, regex, &block)
      event(metric, regex, :max, nil, &block)
    end

    def append(metric, regex, &block)
      event(metric, regex, :to_a, nil, &block)
    end

    def unique(metric, regex, &block)
      event(metric, regex, :uniq, nil, &block)
    end

    def terminate
      @thread.terminate
    end

    private

    def _consume_line(line)
      self.class.update_global_stats(line)
      ts = Time.now.to_i
      @event_definitions.each do |metric, regex, op, value, block|
        begin
          regex.match(line) do |matches|
            value = matches[0] if value.nil?
            value = block.call(matches) if block
            parent.metrics.set(metric, value, op, ts) if value
          end
        rescue => e
          parent.log e
          raise e
        end
        parent.metrics.trim_to(ts - (parent.history || (60 * 60)))
      end
    end
  end
end
