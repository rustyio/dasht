module Dasht
  class LogThread
    attr_accessor :parent

    def initialize(parent, command)
      @parent = parent
      @command = command
    end

    def run
      parent.log "Starting `#{@command}`..."
      @thread = Thread.new do
        begin
          while true
            begin
              IO.popen(@command) do |process|
                process.each do |line|
                  ts = Time.now.to_i
                  parent.collector.add_line(ts, line)
                end
              end
            rescue => e
              parent.log e
            end
            sleep 2
          end
        rescue => e
          parent.log e
          raise e
        end
      end
    end

    def terminate
      @thread.terminate
    end
  end
end
