require 'dasht'

application = ARGV[0]

dasht do |d|
  d.refresh=1

  # Consume Heroku logs.
  d.start "heroku logs --tail --app #{application}"

  # Track some metrics.
  d.count :lines, /.+/

  d.count :bytes, /.+/ do |match|
    match[0].length
  end

  d.append :visitors, /Started GET .* for (\d+\.\d+\.\d+\.\d+) at/ do |matches|
    matches[1]
  end

  counter = 0
  d.interval :counter do
    sleep 1
    counter += 1
  end

  # Publish a board.
  d.board do |b|
    b.metric :counter,  :title => "Counter"
    b.metric :lines,    :title => "Number of Lines"
    b.metric :bytes,    :title => "Number of Bytes"
    b.chart  :bytes,    :title => "Chart of Bytes", :history => 10
    b.map    :visitors, :title => "Visitors", :width => 12, :height => 9
  end
end
