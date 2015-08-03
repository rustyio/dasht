require 'dasht'

dasht do |d|
  # Set some defaults.
  d.resolution = 60
  d.refresh = 5

  # Tail a log.
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

  d.append :places2, /for (\d+\.\d+\.\d+\.\d+) at/ do |matches|
    matches[1]
  end

  counter = 0
  d.interval :counter do
    sleep 1
    counter += 1
  end

  # Publish a board.
  d.board do |b|
    b.metric :counter, :title => "Counter"
    b.metric :lines, :title => "Number of Lines"
    b.metric :bytes, :title => "Number of Bytes"
    b.chart :bytes,  :title => "Chart of Bytes", :history => 10, :width => 3
    b.map :places2,  :title => "Visitors", :width => 12, :height => 9
    # b.scroll :router, :title => "Router Requests"
  end
end
