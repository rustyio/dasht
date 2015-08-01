module Dasht
  class Base
    attr_accessor :port
    attr_accessor :collector
    attr_accessor :rack_app
    attr_accessor :reloader
    attr_accessor :dashboard_builder
    attr_accessor :boards

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

    def event(metric, regex, op = nil, value = nil, options = {}, &block)
      collector.add_event_definition(metric.to_s, regex, op, value, block)
    end

    def count(metric, regex, &block)
      event(metric, regex, :dasht_sum, 1, &block)
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

    def board(name = "default")
      name = name.to_s
      @boards[name] = Board.new(self, name).tap do |b|
        yield(b)
      end
    end

    ### LOG THREADS ###

    def start(command)
      @log_threads[command] = nil
    end

    def tail(path)
      start("tail -F -n 0 \"#{path}\"")
    end

    ### RUN & RELOAD ###

    def run(&block)
      if @already_running
        reload(&block)
        return
      end

      @already_running = true
      @collector.run
      @reloader.run

      block.call(self)

      @log_threads.keys.each do |command|
        @log_threads[command] = LogThread.new(self, command).run
      end

      @rack_app.run(port)
    end

    def reload(&block)
      @collector.reset_event_definitions
      @boards = {}
      @old_log_threads = @log_threads
      @log_threads = {}

      begin
        block.call(self)
      rescue => e
        log e
        raise e
      end

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
