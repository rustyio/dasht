require 'rack'
require 'thread'
require 'erb'
require 'json'

require 'dasht/array_monkeypatching'
require 'dasht/reloader'
require 'dasht/board'
require 'dasht/list'
require 'dasht/metric'
require 'dasht/collector'
require 'dasht/rack_app'
require 'dasht/log_thread'
require 'dasht/base'

class DashtSingleton
  def self.run(&block)
    @@instance ||= Dasht::Base.new
    @@instance.run(&block)
  end
end

def dasht(&block)
  DashtSingleton.run(&block)
end
