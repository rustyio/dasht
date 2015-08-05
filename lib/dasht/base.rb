module Dasht
  class Base
    attr_accessor :metrics
    attr_accessor :rack_app
    attr_accessor :reloader
    attr_accessor :boards

    # Settings.
    attr_accessor :port
    attr_accessor :background
    attr_accessor :default_resolution
    attr_accessor :default_refresh
    attr_accessor :default_width
    attr_accessor :default_height
    attr_accessor :history

    def initialize
      @boards      = {}
      @log_threads = {}
      @metrics     = Metrics.new(self)
      @reloader    = Reloader.new(self)
      @rack_app    = RackApp.new(self)
    end

    def log(s)
      if s.class < Exception
        print "\n#{s}\n"
        print s.backtrace.join("\n")
      else
        print "\r#{s}\n"
      end
    end

    ### DATA INGESTION ###

    def start(command, &block)
      log_thread = @log_threads[command] = LogThread.new(self, command)
      yield(log_thread) if block
      log_thread
    end

    def tail(path)
      start("tail -F -n 0 \"#{path}\"")
    end

    def interval(metric, &block)
      Thread.new do
        begin
          while true
            value = block.call
            metrics.set(metric, value, :last, Time.now.to_i) if value
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
      yield(board) if block
      board
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
      @reloader.run

      block.call(self)

      @log_threads.values.map(&:run)
      @rack_app.run(port)
    end

    def reload(&block)
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
