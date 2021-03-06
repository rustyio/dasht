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
    b.value :counter,  :title => "Counter"
    b.value :lines,    :title => "Number of Lines"
    b.value :bytes,    :title => "Number of Bytes"
    b.chart :bytes,    :title => "Chart of Bytes", :periods => 10
    b.map   :visitors, :title => "Visitors", :width => 12, :height => 9
  end
end
