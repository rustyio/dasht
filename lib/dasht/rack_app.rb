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
        use Rack::Static, :urls => ["/assets"], :root  => context.root_path
        run lambda { |env|
          begin
            context._call(env)
          rescue => e
            context.parent.log e
            raise e
          end
        }
      end
      Rack::Server.start(:app => app, :Port => (port || 8080))
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

      /^\/data$/.match(env["REQUEST_PATH"]) do |match|
        queries = JSON.parse(env['rack.input'].gets)
        now = Time.now.to_i
        data = queries.map do |query|
          metric     = query["metric"]
          resolution = query["resolution"]
          periods    = query["periods"]
          ts = now - (resolution * periods)
          (1..periods).map do |n|
            parent.metrics.get(metric, ts, ts += resolution) || 0
          end
        end

        return ['200', {'Content-Type' => 'application/json'}, [data.to_json]]
      end

      /^\/data\/(.+)/.match(env["REQUEST_PATH"]) do |match|
        parts = match[1].split('/')
        metric     = parts.shift
        resolution = parts.shift.to_i
        periods    = (parts.shift || 1).to_i
        ts = Time.now.to_i - (resolution * periods)
        data = (1..periods).map do |n|
          parent.metrics.get(metric, ts, ts += resolution) || 0
        end
        return ['200', {'Content-Type' => 'application/json'}, [data.to_json]]
      end

      return ['404', {'Content-Type' => 'text/html'}, ["Path not found: #{env['REQUEST_PATH']}"]]
    end
  end
end
