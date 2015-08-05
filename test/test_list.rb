require 'helper'

class TestList < Test::Unit::TestCase
  def test_construction
    list = Dasht::List.new
    ptr1 = list.append(1)
    ptr2 = list.append(2)
    ptr3 = list.append(3)
    assert_equal 6, list.enum(ptr1).to_a.inject(:+)
  end

  def test_trim_to
    list = Dasht::List.new
    ptr1 = list.append(1)
    ptr2 = list.append(2)
    ptr3 = list.append(3)

    list.trim_to(ptr1)
    assert_equal 6, list.enum(ptr1).to_a.inject(:+)

    list.trim_to(ptr2)
    assert_equal 5, list.enum(ptr1).to_a.inject(:+)

    list.trim_to(ptr3)
    assert_equal 3, list.enum(ptr1).to_a.inject(:+)

    ptr4 = list.append(4)
    assert_equal 7, list.enum(ptr1).to_a.inject(:+)

    list.trim_to(ptr4)
    assert_equal 4, list.enum(ptr1).to_a.inject(:+)

    list.trim_to(list.tail_pointer)
    assert_equal nil, list.enum(ptr1).to_a.inject(:+)
  end

  def test_trim_while
    list = Dasht::List.new
    ptr1 = list.append(1)
    ptr2 = list.append(2)
    ptr3 = list.append(3)
    list.trim_while do |data|
      data < 2
    end
    assert_equal 5, list.enum(ptr1).to_a.inject(:+)

    list.trim_while do |data|
      data < 3
    end
    assert_equal 3, list.enum(ptr1).to_a.inject(:+)

    ptr4 = list.append(4)
    assert_equal 7, list.enum(ptr1).to_a.inject(:+)

    list.trim_while do |data|
      data < 4
    end
    assert_equal 4, list.enum(ptr1).to_a.inject(:+)

    list.trim_while do |data|
      data < 5
    end
    assert_equal nil, list.enum(ptr1).to_a.inject(:+)
  end
end
