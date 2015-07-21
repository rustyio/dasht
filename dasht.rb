require 'rack'
require 'thread'

class Array
  def sum; self.inject(:+); end
end

def log(s)
  print "\r#{s}\n"
end

class Dasht
  def self.run(port)
    self.instance.run(port)
  end

  def self.instance
    @instance ||= Base.new
  end

  class Collector
    def initialize
      @metric_values     = {}
      @metric_operations = {}
      @event_definitions = []
      @total_lines       = 0
      @total_bytes       = 0
      @line_queue = Queue.new
    end

    def add_line(line)
      @line_queue.push(line)
    end

    def add_event_definition(metric, regex, op, value, block)
      @event_definitions << [metric, regex, op, value, block]
    end

    def reset_event_definitions
      @event_definitions = []
    end

    def set(metric, value, op = :last)
      secs = Time.now.to_i
      @metric_operations[metric] = op
      @metric_values[metric] ||= {}
      @metric_values[metric][secs] =
        if @metric_values[metric][secs].nil?
          value
        else
          [@values[metric][secs], value].send(op)
        end
    end

    def get(metric, resolution = 60)
      return 0 if @metric_values[metric].nil?
      secs = Time.now.to_i
      values = ((secs - resolution)..secs).map do |n|
        @values[metric][n]
      end.compact.flatten.send(@metric_operations[metric])
    end

    def run
      Thread.new do
        while line = @line_queue.pop
          @total_lines += 1
          @total_bytes += line.length
          print "\rConsumed #{@total_lines} lines (#{@total_bytes} bytes)."
          _consume_line(line)
        end
      end
    end

    private

    def _consume_line(line)
      @event_definitions.each do |metric, regex, op, value, block|
        begin
          regex.match(line) do |matches|
            if value.nil? && block
              value = block.call(matches)
            end
            set(metric, value, op) if value
          end
        rescue => e
          log "Error processing metric #{metric}"
          log "  Regex: #{regex}"
          log "  Line: #{line}"
          log e
        end
      end
    end
  end


  class LogThread
    def initialize(command)
      @command = command
    end

    def run
      log "Starting `#{@command}`..."
      @thread = Thread.new do
        begin
          while true
            begin
              IO.popen(@command) do |process|
                process.each do |line|
                  Dasht.instance.collector.add_line(line)
                end
              end
            rescue => e
              log "Command #{@command} stopped unexpectedly: #{e}. Restarting..."
            end
            sleep 2
          end
        rescue => e
          log e
        end
      end
    end

    def terminate
      @thread.terminate
    end
  end

  module DSL
    def set(metric, value, op = :last)
      Dasht.instance.collector.set(metric, value, op)
    end

    def get(metric, resolution = 60)
      Dasht.instance.collector.get(metric, resolution)
    end

    ### EVENTS ###

    def event(metric, regex, op = nil, value = nil, options = {}, &block)
      Dasht.instance.collector.add_event_definition(metric, regex, op, value, block)
      tile(metric, options)
    end

    def count(metric, regex, options = {})
      event(metric, regex, :sum, 1)
      tile(metric, options.merge(:type => :count))
    end

    def min(metric, regex, options = {}, &block)
      event(metric, regex, :min, nil, block)
      tile(metric, options.merge(:type => :min))
    end

    def max(metric, regex, options = {}, &block)
      event(metric, regex, :max, nil, block)
      tile(metric, options.merge(:type => :max))
    end

    ### DASHBOARDS ###

    def dashboard(name, &block)
      Dasht.instance.add_dashboard(name, &block)
    end

    def tile(metric, options)
      if Dasht.instance.dashboard_builder
        log "Adding tile_type #{metric}"
        Dasht.instance.dashboard_builder << [metric, options]
      end
    end



    ### LOG THREADS ###

    def start(command)
      Dasht.instance.add_log_thread(command)
    end

    def tail(path)
      start("tail -F -n 0 \"#{path}\"")
    end
  end

  class RackApp
    def initialize
    end

    def run(port)
      obj = self
      app = Rack::Builder.new do
        use Rack::Static, :urls => ["/assets"], :root => "assets"
        run lambda { |env| obj._call(env) }
      end
      Rack::Server.start(:app => app, :Port => port)
    end

    def _call(env)
      /\/data\/(.+)\/(.*)/.match(env["REQUEST_PATH"]) do |match|
        metric = match[1]
        resolution = match[2]
        data = Dasht.instance.collector.get(metric, resolution.to_i) || 0
        ['200', {'Content-Type' => 'text/html'}, [data.to_s]]
      end
    end
  end


  class Reloader
    def initialize
      @last_modified = File.mtime($PROGRAM_NAME)
    end

    def changed?
      @last_modified != File.mtime($PROGRAM_NAME)
    end

    def run
      Thread.new do
        while true
          unless changed?
            sleep 1
            next
          end
          log "Reloading #{$PROGRAM_NAME}..."
          Dasht.instance.reload
          @last_modified = File.mtime($PROGRAM_NAME)
        end
      end
    end
  end


  class Base
    attr_accessor :collector
    attr_accessor :rack_app
    attr_accessor :reloader
    attr_accessor :dashboard_builder

    def initialize
      @dashboards    = []
      @log_threads   = {}
      @dashboards    = []
      @last_modified = File.mtime($PROGRAM_NAME)
      @collector     = Collector.new
      @reloader      = Reloader.new
      @rack_app      = RackApp.new
    end

    def add_log_thread(command)
      @log_threads[command] = nil
    end

    def add_dashboard(name, &block)
      @dashboard_builder = []
      yield
      @dashboards << [name, @dashboard_builder]
      @dashboard_builder = nil
    end

    def run(port)
      @collector.run
      @reloader.run
      @log_threads.keys.each do |command|
        @log_threads[command] = LogThread.new(command).run
      end
      @rack_app.run(port)
    end

    def reload
      @collector.reset_event_definitions
      @dashboards = []

      # Start or stop loggers as appropriate.
      @old_log_threads = @log_threads
      @log_threads = {}
      eval IO.read($PROGRAM_NAME)
      @log_threads.keys.each do |command|
        @log_threads[command] = @old_log_threads.delete(command)
        @log_threads[command] ||= Dash::LogThread.new(command).run
      end
      @old_log_threads.keys.each do |command|
        _stop_log_thread(command)
      end
    end

    private

    def _stop_log_thread(command)
      log "Stopping `#{command}`."
      @log_threads[command].terminate
      @log_threads.delete(command)
    end
  end
end


def dasht(port = 4000)
  return if @already_serving
  @already_serving = true
  Dasht.run(port)
end

include Dasht::DSL
