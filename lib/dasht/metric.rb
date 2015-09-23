# Dasht::Metric - Simple in-memory time-series data structure with the
# following properties:
#
# 1. Sparse. Only stores time stamps for intervals with known data,
#    and only stores one timestamp per interval.
# 2. Flexible aggregation using Ruby blocks during both read and
#    write.
# 3. Read values between two timestamps.
#
# The Dasht::Metric structure is formed using two Dasht::List
# objects. One object tracks data, the other object tracks a list of
# checkpoints and their corresponding index into the data.
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
      return @data.to_s + " (last: #{@last_item})"
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

    def trim_to(ts)
      pointer = nil
      @checkpoints.trim_while do |s, p|
        pointer = p
        (s || 0) < ts
      end
      @data.trim_to(pointer)
      return
    end

    def enum(start_ts, end_ts = nil)
      # Get a pointer to our location in the data.
      start_pointer = nil
      end_pointer = nil
      prev_p = nil
      @checkpoints.enum.each do |s, p|
        start_pointer ||= p if start_ts <= (s || 0)
        end_pointer   ||= prev_p if end_ts && end_ts <= (s || 0)
        break if start_pointer && (end_ts.nil? || end_pointer)
        prev_p = p
      end
      start_pointer ||= @data.tail_pointer
      end_pointer ||= @data.tail_pointer

      # Enumerate through the data, then tack on the last item.
      return Enumerator.new do |yielder|
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
