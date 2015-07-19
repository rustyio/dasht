require 'rack'
require 'webrick'
require 'thread'

class Array
  def sum; self.inject(:+); end
end

class Collector
  def initialize
    @values            = {}
    @operations        = {}
    @event_definitions = []
    @log_threads       = {}
    @total_lines       = 0
    @total_bytes       = 0
    @last_modified     = File.mtime($PROGRAM_NAME)
  end

  def log(s)
    print "\r#{s}\n"
  end

  ### BASICS ###

  def set(label, value, op = :last)
    secs = Time.now.to_i
    @operations[label] = op
    @values[label] ||= {}
    @values[label][secs] =
      if @values[label][secs].nil?
        value
      else
        [@values[label][secs], value].send(op)
      end
  end

  def get(label, resolution = 60)
    return 0 if @values[label].nil?
    secs = Time.now.to_i
    values = ((secs - resolution)..secs).map do |n|
      @values[label][n]
    end.compact.flatten.send(@operations[label])
  end

  ### LISTEN FOR EVENTS ###

  def event(label, regex, op = nil, value = nil, &block)
    @event_definitions << [label, regex, op, value, block]
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

  ### CONSUMING DATA ###

  def _consume_log_line(line)
    @total_lines += 1
    @total_bytes += line.length
    print "\rConsumed #{@total_lines} lines (#{@total_bytes} bytes)."

    @event_definitions.each do |label, regex, op, value, block|
      regex.match(line) do |matches|
        if value.nil? && block
          value = block.call(matches)
        end
        set(label, value, op) if value
      end
    end
  end

  def _start_log_thread(command)
    log "Starting `#{command}`..."
    Thread.new do
      begin
        while true
          begin
            IO.popen(command) do |process|
              process.each do |line|
                _consume_log_line(line)
              end
            end
          rescue => e
            log "Command #{command} stopped unexpectedly: #{e}. Restarting..."
          end
          sleep 2
        end
      rescue => e
        log e
      end
    end
  end

  def _stop_log_thread(command)
    log "Stopping `#{command}`."
    @log_threads[command].terminate
    @log_threads.delete(command)
  end

  def tail(path)
    start "tail -F -n 0 \"#{path}\""
  end

  def start(command)
    @log_threads[command] = nil
  end

  def run
    return if @already_serving
    @already_serving = true

    log "Running #{$PROGRAM_NAME}..."

    # Start all log thread commands.
    @log_threads.keys.each do |command|
      @log_threads[command] = _start_log_thread(command)
    end

    # Reload if necessary.
    _start_reload_thread
  end

  ### PUBLISHING DATA ###

  def _rack_request(env)
    data = nil
    /\/data\/(.+)\/(.*)/.match(env["REQUEST_PATH"]) do |match|
      label = match[1]
      resolution = match[2]
      data = get(label, resolution.to_i) || 0
      ['200', {'Content-Type' => 'text/html'}, [data.to_s]]
    end
  end

  ### RELOADING THE FILE ###

  def _start_reload_thread
    Thread.new do
      while true
        if @last_modified == File.mtime($PROGRAM_NAME)
          sleep 1
        end
        log "Reloading #{$PROGRAM_NAME}..."
        begin
          @event_definitions = []
          @old_log_threads = @log_threads
          @log_threads = {}
          eval IO.read($PROGRAM_NAME)
          @log_threads.keys.each do |command|
            @log_threads[command] = @old_log_threads.delete(command)
            @log_threads[command] ||= _start_log_thread(command)
          end
          @old_log_threads.keys.each do |command|
            _stop_log_thread(command)
          end
        rescue => e
          log e
        end
        @last_modified == File.mtime($PROGRAM_NAME)
      end
    end
  end
end

COLLECTOR = Collector.new
[
  :set, :get, :event, :count, :min, :max, :tail, :start
].each do |method|
  define_method method do |*args|
    COLLECTOR.send(method, *args)
  end
end

def collector
  COLLECTOR.run
  Rack::Builder.new do
    use Rack::CommonLogger
    use Rack::ShowExceptions
    use Rack::Static, {
          :urls => ["/js", "/css", "/images", "/dashboards"],
          :root => "public"
        }
    run lambda { |env| COLLECTOR._rack_request(env) }
  end
end
