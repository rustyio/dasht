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

  d.append :router, /router.*method=(\w+) path="([^\"]+)"/ do |match|
    "#{match[1]} #{match[2]}"
  end

  d.append :places, /"lead_property_address"=>"([^"]+)"/ do |matches|
    matches[1]
  end

  # Publish a board.
  d.board do |b|
    b.value :lines, :title => "Number of Lines", :resolution => 999, :width => 2, :height => 1
    b.value :bytes, :title => "Number of Bytes", :resolution => 999, :width => 2, :height => 1
    b.value :bytes, :title => "Number of Bytes", :resolution => 999, :width => 2, :height => 1
    b.map :places, :title => "Incoming Leads", :width => 6, :height => 3, :n => 999
    # b.scroll :router, :title => "Router Requests"
  end
end
