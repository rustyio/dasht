require './dasht.rb'

tail "/tmp/test1.log"
tail "/tmp/test2.log"

count "lines", /.*/

run collector
