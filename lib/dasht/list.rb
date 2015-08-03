# Dasht::List - Simple list structure following properties:
#
# 1. Fast writes. Appends to a list.
# 2. Fast reads by index. Indexed by position in the list.
# 3. Fast deletes that preserve indexes. Removes items from the front
#    of the list.
# 4. Simple (but not necessarily fast) aggregation. Enumerate values
#    between pointers.
#
# The Dasht::List structure is formed using a Ruby Array (values),
# plus a counter of how many items have been deleted (offset).
# Whenever data is deleted from the head of the list, the offset is
# incremented.

module Dasht
  class List
    attr_accessor :values
    attr_accessor :offset

    def initialize
      @offset = 0
      @values = []
    end

    def to_s
      return @values.to_s
    end

    # Public: Get a pointer to the first value.
    def head_pointer
      return offset
    end

    # Public: Get a pointer to right after the last value.
    def tail_pointer
      return offset + @values.length
    end

    # Public: Get the value at a given pointer, or nil if the pointer
    # is no longer valid.
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

    # Public: Remove data up to (but not including) the specified pointer.
    def trim_to(pointer)
      return if pointer.nil?
      index = _pointer_to_index(pointer)
      @offset += index
      @values = @values.slice(index, @values.length)
      return
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

    # Convert a pointer to an index in the list.
    def _pointer_to_index(pointer)
      return [pointer - offset, 0].max
    end
  end
end
