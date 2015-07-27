require 'test/unit'
require 'dasht/metric'

class MetricTest < Test::Unit::TestCase
  def test_counting
    m = Dasht::Metric.new
    proc = Proc.new do |old_value, new_value|
      (old_value || 1) * new_value
    end
    m.append(4, 1, &proc)
    m.append(5, 1, &proc)
    m.append(6, 2, &proc)
    m.append(7, 2, &proc)

    assert_equal 62, m.enum(1).inject(:+)
    assert_equal 42, m.enum(2).inject(:+)
  end

  def test_lists
    m = Dasht::Metric.new
    proc = Proc.new do |old_value, new_value|
      (old_value || []).push(new_value)
    end
    m.append(:a, 1, &proc)
    m.append(:b, 1, &proc)
    m.append(:c, 2, &proc)
    m.append(:d, 2, &proc)

    assert_equal [:a, :b, :c, :d], m.enum(1).to_a.flatten
    assert_equal [:c, :d], m.enum(2).to_a.flatten
  end
end
