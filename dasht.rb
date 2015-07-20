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

    def add_event_definition(label, regex, op, value, block)
      @event_definitions << [label, regex, op, value, block]
    end

    def reset_event_definitions
      @event_definitions = []
    end

    def set(label, value, op = :last)
      secs = Time.now.to_i
      @metric_operations[label] = op
      @metric_values[label] ||= {}
      @metric_values[label][secs] =
        if @metric_values[label][secs].nil?
          value
        else
          [@values[label][secs], value].send(op)
        end
    end

    def get(label, resolution = 60)
      return 0 if @metric_values[label].nil?
      secs = Time.now.to_i
      values = ((secs - resolution)..secs).map do |n|
        @values[label][n]
      end.compact.flatten.send(@metric_operations[label])
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
      @event_definitions.each do |label, regex, op, value, block|
        begin
          regex.match(line) do |matches|
            if value.nil? && block
              value = block.call(matches)
            end
            set(label, value, op) if value
          end
        rescue => e
          log "Error processing label #{label}"
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
    def set(label, value, op = :last)
      Dasht.instance.collector.set(label, value, op)
    end

    def get(label, resolution = 60)
      Dasht.instance.collector.get(label, resolution)
    end

    ### EVENTS ###

    def event(label, regex, op = nil, value = nil, &block)
      Dasht.instance.collector..add_event_definition(label, regex, op, value, block)
    end

    def count(label, regex)
      event(label, regex, :sum, 1)
    end

    def min(label, regex, &block)
      event(label, regex, :min, nil, block)
    end

    def max(label, regex, &block)
      event(label, regex, :max, nil, block)
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
        label = match[1]
        resolution = match[2]
        data = Dasht.instance.collector.get(label, resolution.to_i) || 0
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
          log "Checking..."
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

    def initialize
      @dashboards    = []
      @log_threads   = {}
      @last_modified = File.mtime($PROGRAM_NAME)
      @collector     = Collector.new
      @reloader      = Reloader.new
      @rack_app      = RackApp.new
    end

    def add_log_thread(command)
      @log_threads[command] = nil
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


  # ### DASHBOARDS

  # def dashboard(name, &block)
  #   @dashboard_tiles = []
  #   yield
  #   @dashboards << [name, @dashboard_tiles]
  #   @dashboard_tiles = nil
  # end


def dasht(port = 4000)
  return if @already_serving
  @already_serving = true
  Dasht.run(port)
end

include Dasht::DSL
