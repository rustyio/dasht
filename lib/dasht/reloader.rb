module Dasht
  class Reloader
    attr_accessor :parent

    def initialize(parent)
      @parent        = parent
      @last_modified = File.mtime($PROGRAM_NAME)
    end

    def changed?
      @last_modified != File.mtime($PROGRAM_NAME)
    end

    def run
      Thread.new do
        while true
          unless changed?
            sleep 0.3
            next
          end
          parent.log("Reloading #{$PROGRAM_NAME}...")
          eval(IO.read($PROGRAM_NAME))
          @last_modified = File.mtime($PROGRAM_NAME)
        end
      end
    end
  end
end
