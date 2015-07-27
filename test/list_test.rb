require 'test/unit'
require 'dasht/list'

class ListTest < Test::Unit::TestCase
  def test_construction
    list = Dasht::List.new
    ptr1 = list.append(1)
    ptr2 = list.append(2)
    ptr3 = list.append(3)
    assert_equal 6, list.enum(ptr1).to_a.inject(:+)
  end

  def test_trim
    list = Dasht::List.new
    ptr1 = list.append(1)
    ptr2 = list.append(2)
    ptr3 = list.append(3)
    list.trim_while do |data|
      data !=2
    end
    assert_equal 5, list.enum(ptr1).to_a.inject(:+)
  end
end
