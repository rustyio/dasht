require 'dasht'
require 'net/http'
require 'timeout'

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
    begin
      Timeout::timeout(0.2) do
        h = JSON.parse(Net::HTTP.get(URI.parse(url)))
        { :latitude => h['latitude'], :longitude => h['longitude'] }
      end
    rescue Timeout::Error => e
      print "\nLookup failed for #{url}!\n"
      nil
    end
  end

  # Publish a board.
  d.board do |b|
    b.metric :lines, :title => "Number of Lines", :resolution => 999, :width => 4, :height => 3, :fontsize => :large
    b.metric :bytes, :title => "Number of Bytes", :resolution => 999, :width => 4, :height => 3, :fontsize => :large
    b.metric :bytes, :title => "Number of Bytes", :resolution => 999, :width => 4, :height => 3, :fontsize => :large
    b.map :places2, :title => "Incoming Leads", :width => 12, :height => 9, :n => 999
    # b.scroll :router, :title => "Router Requests"
  end
end
