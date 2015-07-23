module Dasht
  class Base
    attr_accessor :port
    attr_accessor :collector
    attr_accessor :rack_app
    attr_accessor :reloader
    attr_accessor :dashboard_builder

    def initialize(port)
      @boards      = []
      @log_threads = {}
      @collector   = Collector.new
      @reloader    = Reloader.new(self)
      @rack_app    = RackApp.new(self)
    end

    def log(s)
      print "\r#{s}\n"
    end

    ### COLLECTOR ###

    def set(metric, value, op = :last)
      collector.set(metric, value, op)
    end

    def get(metric, resolution = 60)
      collector.get(metric, resolution)
    end

    ### EVENTS ###

    def event(metric, regex, op = nil, value = nil, options = {}, &block)
      collector.add_event_definition(metric, regex, op, value, block)
    end

    def count(metric, regex, options = {}, &block)
      event(metric, regex, :sum, 1, &block)
    end

    def min(metric, regex, options = {}, &block)
      event(metric, regex, :min, nil, block)
    end

    def max(metric, regex, options = {}, &block)
      event(metric, regex, :max, nil, block)
    end

    ### DASHBOARD ###

    def board(name)
      @boards << Board.new(self, name).tap do |b|
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
      @collector.run
      @reloader.run

      block.call(self)

      @log_threads.keys.each do |command|
        @log_threads[command] = LogThread.new(self, command).run
      end

      @rack_app.run(port)
    end

    def reload(&block)
      log "Reloading dasht instance."
      @collector.reset_event_definitions
      @boards = []
      @old_log_threads = @log_threads
      @log_threads = {}

      block.call(self)

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
