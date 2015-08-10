require 'dasht'

application = ARGV[0]

dasht do |d|
  # Consume Heroku logs.
  d.start "heroku logs --tail --app #{application}" do |l|
    # Track some metrics.
    l.count :lines, /.+/

    l.count :bytes, /.+/ do |match|
      match[0].length
    end

    l.append :visitors, /Started GET .* for (\d+\.\d+\.\d+\.\d+) at/ do |matches|
      matches[1]
    end
  end

  counter = 0
  d.interval :counter do
    sleep 1
    counter += 1
  end

  # Publish a board.
  d.board do |b|
    b.map   :visitors, :title => "Visitors", :width => 8, :height => 12
    b.value :counter,  :title => "Counter", :width => 4
    b.value :lines,    :title => "Number of Lines", :width => 4
    b.value :bytes,    :title => "Number of Bytes", :width => 4
    b.chart :bytes,    :title => "Chart of Bytes", :periods => 10, :width => 4
  end
end
