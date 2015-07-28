module Dasht
  class RackApp
    attr_accessor :parent

    def initialize(parent)
      @parent = parent
    end

    def root_path
      File.join(File.dirname(__FILE__), "..", "..")
    end

    def run(port)
      context = self
      app = Rack::Builder.new do
        use Rack::Static, :urls => ["/assets"], :root => context.root_path
        run lambda { |env|
          begin
            context._call(env)
          rescue => e
            parent.log "Error processing metric #{metric}"
            parent.log "  Regex: #{regex}"
            parent.log "  Line: #{line}"
            parent.log "#{e}\n#{e.backtrace.join('\n')}\n"
          end
        }
      end
      Rack::Server.start(:app => app, :Port => port)
    end

    def _call(env)
      if "/" == env["REQUEST_PATH"] && parent.boards["default"]
        return ['200', {'Content-Type' => 'text/html'}, [parent.boards["default"].to_html]]
      end

      /^\/boards\/(.+)$/.match(env["REQUEST_PATH"]) do |match|
        board = match[1]
        if parent.boards[board]
          return ['200', {'Content-Type' => 'text/html'}, [parent.boards[board].to_html]]
        else
          return ['404', {'Content-Type' => 'text/html'}, ["Board #{board} not found."]]
        end
      end

      /^\/data\/(.+)\/(\d+)/.match(env["REQUEST_PATH"]) do |match|
        metric = match[1]
        resolution = match[2]
        data = parent.collector.get(metric, resolution.to_i) || 0
        return ['200', {'Content-Type' => 'text/html'}, [data.to_s]]
      end

      return ['404', {'Content-Type' => 'text/html'}, ["Path not found: #{env['REQUEST_PATH']}"]]
    end
  end
end
