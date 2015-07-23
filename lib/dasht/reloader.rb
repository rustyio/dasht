module Dasht
  class Reloader
    attr_accessor :dasht

    def initialize(dasht)
      @dasht         = dasht
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
          dasht.reload
          @last_modified = File.mtime($PROGRAM_NAME)
        end
      end
    end
  end
end
