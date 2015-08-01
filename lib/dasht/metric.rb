module Dasht
  class Metric
    attr_reader :data, :checkpoints

    def initialize
      @checkpoints = List.new
      @data = List.new
      @last_item = nil
      @last_ts = nil
    end

    def to_s
      @data.to_s + " (last: #{@last_item})"
    end

    def append(data, ts, &block)
      # Maybe checkpoint the time.
      if @last_ts == ts
        @last_item = yield(@last_item, data)
      else
        if @last_ts
          pointer = @data.append(@last_item)
          @checkpoints.append([@last_ts, pointer])
        end
        @last_ts = ts
        @last_item = nil
        @last_item = yield(@last_item, data)
      end
      return
    end

    def enum(ts)
      # Get a pointer to our location in the data.
      pointer = @data.tail_pointer
      @checkpoints.enum.each do |s, p|
        if ts <= s
          pointer = p
          break
        end
      end

      # Enumerate through the data, then tack on the last item.
      Enumerator.new do |yielder|
        @data.enum(pointer).each do |data|
          yielder << data
        end
        if @last_item && ts <= @last_ts
          yielder << @last_item
        end
      end
    end
  end
end
