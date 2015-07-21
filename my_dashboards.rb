require './dasht.rb'

tail "/tmp/test1.log"
tail "/tmp/test2.log"

count :lines, /.*/

count :bytes, /.*/ do |match|
  match[0].length
end

dashboard :test do |d|
  d.value :caption => "Number of lines.",
          :metric => [:lines, 60, 1]
  print d.to_html

  # two_value :caption    => "Number of lines.",
  #           :metric     => [:lines, 60, 1],
  #           :subcaption => "Number of bytes.",
  #           :submetric  => [:bytes, 60, 1]

  # line_chart :caption => "Lines per minute.",
  #            :metric  => [:lines, 60, 1]
end

dasht
