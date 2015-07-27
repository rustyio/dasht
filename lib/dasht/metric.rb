module Dasht
  class Metric
    attr_reader :data, :checkpoints
    Checkpoint = Struct.new(:time)

    def initialize
      @checkpoints = List.new
      @data = List.new
      @last_item = nil
      @last_secs = nil
    end

    def to_s
      @data.to_s + " (last: #{@last_item})"
    end

    def append(data, time = Time.now, &block)
      # Maybe checkpoint the time.
      secs = time.to_i
      if @last_secs == secs
        @last_item = yield(@last_item, data)
      else
        if @last_secs
          pointer = @data.append(@last_item)
          @checkpoints.append([@last_secs, pointer])
        end
        @last_secs = secs
        @last_item = nil
        @last_item = yield(@last_item, data)
      end
      return
    end

    def enum(time)
      # Get a pointer to our location in the data.
      secs = time.to_i
      pointer = @data.tail_pointer
      @checkpoints.enum.each do |s, p|
        if secs <= s
          pointer = p
          break
        end
      end

      # Enumerate through the data, then tack on the last item.
      Enumerator.new do |yielder|
        @data.enum(pointer).each do |data|
          yielder << data
        end
        if @last_item && secs <= @last_secs
          yielder << @last_item
        end
      end
    end
  end
end
