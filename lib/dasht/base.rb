module Dasht
  class Base
    attr_accessor :port
    attr_accessor :collector
    attr_accessor :rack_app
    attr_accessor :reloader
    attr_accessor :dashboard_builder
    attr_accessor :boards
    attr_accessor :background
    attr_accessor :default_resolution
    attr_accessor :default_refresh
    attr_accessor :default_width
    attr_accessor :default_height
    attr_accessor :history

    def initialize
      @boards      = {}
      @log_threads = {}
      @collector   = Collector.new(self)
      @reloader    = Reloader.new(self)
      @rack_app    = RackApp.new(self)
    end

    def log(s)
      if s.class < Exception
        print "\r#{s}\n"
        print s.backtrace.join("\n")
      else
        print "\r#{s}\n"
      end
    end

    ### COLLECTOR ###

    def set(metric, value, op = :last)
      collector.set(metric, value, op, Time.now.to_i)
    end

    def get(metric, resolution = 60)
      collector.get(metric, resolution)
    end

    ### EVENTS ###

    def event(metric, regex, op, value = nil, &block)
      collector.add_event_definition(metric, regex, op, value, block)
    end

    def count(metric, regex, &block)
      event(metric, regex, :dasht_sum, 1, &block)
    end

    def gauge(metric, regex, &block)
      event(metric, regex, :last, nil, &block)
    end

    def min(metric, regex, &block)
      event(metric, regex, :min, nil, &block)
    end

    def max(metric, regex, &block)
      event(metric, regex, :max, nil, &block)
    end

    def append(metric, regex, &block)
      event(metric, regex, :to_a, nil, &block)
    end

    def unique(metric, regex, &block)
      event(metric, regex, :uniq, nil, &block)
    end

    def interval(metric, &block)
      Thread.new do
        begin
          while true
            value = block.call
            set(metric, value, :last) if value
          end
        rescue => e
          log e
          raise e
        end
      end
    end

    ### DASHBOARD ###

    def views_path
      File.join(File.dirname(__FILE__), "..", "..", "views")
    end

    def system_plugins_path
      File.join(File.dirname(__FILE__), "..", "..", "assets", "plugins")
    end

    def user_plugins_path
      File.join(File.dirname($PROGRAM_NAME), "plugins")
    end

    def board(name = "default", &block)
      name = name.to_s
      board = @boards[name] = Board.new(self, name)
      yield(b) if block
      board
    end

    ### LOG THREADS ###

    def start(command, &block)
      log_thread = @log_threads[command] = LogThread.new(self, command)
      yield(log_thread) if block
      log_thread
    end

    def tail(path)
      start("tail -F -n 0 \"#{path}\"")
    end

    ### RUN & RELOAD ###

    def run(&block)
      if @already_running
        begin
          reload(&block)
        rescue => e
          log e
        end
        return
      end

      @already_running = true
      @collector.run
      @reloader.run

      block.call(self)

      @log_threads.values.map(&:run)
      @rack_app.run(port)
    end

    def reload(&block)
      @collector.reset_event_definitions
      @boards = {}
      @log_threads.values.map(&:terminate)
      @log_threads = {}

      begin
        block.call(self)
      rescue => e
        log e
        raise e
      end

      @log_threads.values.map(&:run)
    end
  end
end
