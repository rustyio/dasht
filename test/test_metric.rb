require 'helper'

class TestMetric < Test::Unit::TestCase
  def test_counting
    m = Dasht::Metric.new
    proc = Proc.new do |old_value, new_value|
      (old_value || 0) + new_value
    end
    m.append(4, 1, &proc)
    m.append(5, 1, &proc)
    m.append(6, 2, &proc)
    m.append(7, 2, &proc)

    assert_equal 22, m.enum(1).inject(:+)
    assert_equal 13, m.enum(2).inject(:+)
    assert_equal 9, m.enum(1,2).inject(:+)
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
    assert_equal [:a, :b], m.enum(1, 2).to_a.flatten
  end

  def test_trim_to
    m = Dasht::Metric.new
    proc = Proc.new do |old_value, new_value|
      (old_value || []).push(new_value)
    end
    m.append(:a, 1, &proc)
    m.append(:b, 1, &proc)
    m.append(:c, 2, &proc)
    m.append(:d, 2, &proc)

    m.trim_to(1)
    assert_equal [:a, :b, :c, :d], m.enum(0).to_a.flatten

    m.trim_to(2)
    assert_equal [:c, :d], m.enum(0).to_a.flatten

    m.append(:e, 3, &proc)
    m.append(:f, 3, &proc)
    assert_equal [:c, :d, :e, :f], m.enum(0).to_a.flatten


    m.trim_to(3)
    assert_equal [:e, :f], m.enum(0).to_a.flatten
  end
end
