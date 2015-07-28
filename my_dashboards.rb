require 'dasht'

dasht do |d|
  # Tail a log.

  d.tail "/tmp/test.log"

  # Track some metrics.

  # d.count :lines, /.+/

  # d.count :bytes, /.+/ do |match|
  #   match[0].length
  # end

  d.append :test, /.+/ do |match|
    match[0]
  end

  # Publish a board.
  d.board do |b|
    b.value :lines, :title => "Number of Lines", :resolution => 10
    b.value :bytes, :title => "Number of Bytes", :resolution => 10
    b.value :bytes, :title => "Number of Bytes", :resolution => 10
    # b.top   :bytes, :title => "Top Lengths", :n => 5
  end
end
