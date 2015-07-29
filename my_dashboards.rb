require 'dasht'

dasht do |d|
  # Tail a log.

  # d.tail "/tmp/test.log"
  d.start "heroku logs --tail --app doris"

  # Track some metrics.

  d.count :lines, /.+/

  d.count :bytes, /.+/ do |match|
    match[0].length
  end

  d.append :log, /.+/ do |match|
    match[0]
  end

  # Publish a board.
  d.board do |b|
    b.value :lines, :title => "Number of Lines", :resolution => 999
    b.value :bytes, :title => "Number of Bytes", :resolution => 999
    b.scroll :log, :title => "The Log"
  end
end
