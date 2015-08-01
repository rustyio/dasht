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

    def enum(start_ts, end_ts = nil)
      # Get a pointer to our location in the data.
      start_pointer = nil
      end_pointer = nil
      prev_p = nil
      @checkpoints.enum.each do |s, p|
        start_pointer ||= p if start_ts <= s
        end_pointer   ||= prev_p if end_ts && end_ts <= s
        break if start_pointer && (end_ts.nil? || end_pointer)
        prev_p = p
      end
      start_pointer ||= @data.tail_pointer
      end_pointer ||= @data.tail_pointer

      # Enumerate through the data, then tack on the last item.
      Enumerator.new do |yielder|
        @data.enum(start_pointer, end_pointer).each do |data|
          yielder << data
        end
        # Maybe include the last item.
        if @last_item &&
           (start_ts <= @last_ts) &&
           (end_ts.nil? || (@last_ts < end_ts))
          yielder << @last_item
        end
      end
    end
  end
end
