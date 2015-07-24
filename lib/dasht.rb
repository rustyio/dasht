require 'thread'
require 'rack'
require 'erb'
require 'json'

require 'dasht/reloader'
require 'dasht/board'
require 'dasht/collector'
require 'dasht/rack_app'
require 'dasht/log_thread'
require 'dasht/base'

class Array
  def sum; self.compact.inject(:+); end
end

class DashtSingleton
  def self.run(&block)
    @@instance ||= Dasht::Base.new
    @@instance.run(&block)
  end
end

def dasht(&block)
  DashtSingleton.run(&block)
end
