require 'dasht'
# require 'dasht/dsl'

dasht do |d|

  # Tail some logs...

  d.tail "/tmp/test1.log"
  d.tail "/tmp/test2.log"

  # Generate some metrics...

  d.count :lines, /.*/
  d.count :bytes, /.*/ do |match|
    match[0].length
  end

  # Publish some boards...

  d.board do |b|
    b.value :caption => "Number of lines.",
            :metric => [:lines, 60, 1]
  end
end
