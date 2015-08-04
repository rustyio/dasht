require 'dasht'

dasht do |d|
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

  d.unique :places, /"lead_property_address"=>"([^"]+)"/ do |matches|
    matches[1]
  end

  d.unique :places2, /for (\d+\.\d+\.\d+\.\d+) at/ do |matches|
    matches[1]
  end

  counter = 0
  d.interval :counter do
    sleep 1
    counter += 1
  end

  # Publish a board.
  d.board do |b|
    b.default_refresh = 10
    b.value :counter, :title => "Counter"
    b.value :lines,   :title => "Number of Lines"
    b.value :bytes,   :title => "Number of Bytes"
    b.chart :bytes,   :title => "Chart of Bytes", :periods => 10, :width => 3
    b.map   :places2, :title => "Visitors", :width => 12, :height => 9
  end
end
