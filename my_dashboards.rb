require 'dasht'

dasht do |d|
  # Tail a log.

  d.tail "/tmp/test.log"

  # Track some metrics.

  d.count :lines, /.*/
  d.count :bytes, /.*/ do |match|
    match[0].length
  end

  # Publish a board.
  d.board do |b|
    b.value :lines, :title => "Number of Lines"
    b.value :bytes, :title => "Number of Bytes"
    b.value :bytes, :title => "Number of Bytes"
    b.value :bytes, :title => "Number of Bytes", :min => 0, :max => 200
  end
end
