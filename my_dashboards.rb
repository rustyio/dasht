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
    b.value :lines, :title => "Number of lines."
    # b.value :bytes, :text => "Number of bytes."
    # b.value :bytes, :text => "Number of bytes2."
  end
end
