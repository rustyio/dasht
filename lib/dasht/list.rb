### List - Lightweight structure for storing data with the following properties.
###
### 1. Quick storage. Simply append to a list.
### 2. Indexed by position in the list.
### 3. Allow deleting data from the front of the list without invalidating indexes.

module Dasht
  class List
    attr_accessor :values
    attr_accessor :offset

    def initialize
      @offset = 0
      @values = []
    end

    def to_s
      @values.to_s
    end

    def head_pointer
      return offset
    end

    def tail_pointer
      offset + @values.length
    end

    # Public: Get the value at pointer.
    def get(pointer)
      index = _pointer_to_index(pointer)
      return @values[index]
    end

    # Public: Return an enumerator that walks through the list, yielding
    # data.
    def enum(start_pointer = nil, end_pointer = nil)
      index = _pointer_to_index(start_pointer || head_pointer)
      end_index = _pointer_to_index(end_pointer || tail_pointer)
      return Enumerator.new do |yielder|
        while index < end_index
          yielder << @values[index]
          index += 1
        end
      end
    end

    # Public: Add data to the list.
    # Returns a pointer to the new data.
    def append(data)
      pointer = self.tail_pointer
      @values << data
      return pointer
    end

    # Public: Walk through the list, removing links from the list while
    # the block returns true. Stop when it returns false.
    def trim_while(&block)
      while (@values.length > 0) && yield(@values.first)
        @values.shift
        @offset += 1
      end
      return
    end

    private

    def _pointer_to_index(pointer)
      [pointer - offset, 0].max
    end
  end
end
