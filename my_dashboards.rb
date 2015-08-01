require 'dasht'
require 'net/http'

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
    url = "http://freegeoip.net/json/#{matches[1]}"
    h = JSON.parse(Net::HTTP.get(URI.parse(url)))
    { :latitude => h['latitude'], :longitude => h['longitude'] }
  end

  # Publish a board.
  d.board do |b|
    b.metric :lines, :title => "Number of Lines", :resolution => 999, :width => 2, :height => 1, :fontsize => :large
    b.metric :bytes, :title => "Number of Bytes", :resolution => 999, :width => 2, :height => 1, :fontsize => :large
    b.metric :bytes, :title => "Number of Bytes", :resolution => 999, :width => 2, :height => 1, :fontsize => :large
    b.map :places2, :title => "Incoming Leads", :width => 6, :height => 3, :n => 999
    # b.scroll :router, :title => "Router Requests"
  end
end
