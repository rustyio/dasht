module Dasht
  class LogThread
    attr_accessor :dasht

    def initialize(dasht, command)
      @dasht = dasht
      @command = command
    end

    def run
      dasht.log "Starting `#{@command}`..."
      @thread = Thread.new do
        begin
          while true
            begin
              IO.popen(@command) do |process|
                process.each do |line|
                  dasht.collector.add_line(line)
                end
              end
            rescue => e
              dasht.log "Command #{@command} stopped unexpectedly: #{e}. Restarting..."
            end
            sleep 2
          end
        rescue => e
          dasht.log e
        end
      end
    end

    def terminate
      @thread.terminate
    end
  end
end
