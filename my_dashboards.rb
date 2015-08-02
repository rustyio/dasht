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

  d.append :places2, /for (\d+\.\d+\.\d+\.\d+) at/ do |matches|
    matches[1]
  end

  # Publish a board.
  d.board do |b|
    b.metric :lines, :title => "Number of Lines", :resolution => 999, :refresh => 5, :width => 3, :height => 3, :fontsize => :large
    b.metric :bytes, :title => "Number of Bytes", :resolution => 999, :refresh => 5, :width => 3, :height => 3, :fontsize => :large
    b.chart  :bytes, :title => "Chart of Bytes", :resolution => 60, :refresh => 5, :width => 6, :height => 3
    b.map    :places2, :title => "Incoming Leads", :resolution => 10, :history => 6, :refresh => 5, :width => 12, :height => 9, :n => 999
    # b.scroll :router, :title => "Router Requests"
  end
end
