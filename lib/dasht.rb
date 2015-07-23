require 'thread'
require 'rack'
require 'erb'

require 'dasht/reloader'
require 'dasht/board'
require 'dasht/collector'
require 'dasht/rack_app'
require 'dasht/log_thread'
require 'dasht/base'

class Array
  def sum; self.compact.inject(:+); end
end

def dasht(port = 4000, &block)
  if @dasht_instance.nil?
    @dasht_instance = Dasht::Base.new(port)
    @dasht_instance.run(&block)
  else
    @dasht_instance.reload(&block)
  end
end
