class Array
  def dasht_sum
    self.compact.inject(:+) || 0;
  end
end
