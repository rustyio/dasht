module Dasht
  class RackApp
    attr_accessor :dasht

    def initialize(dasht)
      @dasht = dasht
    end

    def run(port)
      obj = self
      app = Rack::Builder.new do
        use Rack::Static, :urls => ["/assets"], :root => "assets"
        run lambda { |env| obj._call(env) }
      end
      Rack::Server.start(:app => app, :Port => port)
    end

    def _call(env)
      /\/data\/(.+)\/(.*)/.match(env["REQUEST_PATH"]) do |match|
        metric = match[1]
        resolution = match[2]
        data = dasht.collector.get(metric, resolution.to_i) || 0
        return ['200', {'Content-Type' => 'text/html'}, [data.to_s]]
      end

      /\/boards\/(.+)/.match(env["REQUEST_PATH"]) do |match|
        board = match[1]
        if dasht.boards[board]
          return ['200', {'Content-Type' => 'text/html'}, [dasht.boards[board].to_html]]
        else
          return ['404', {'Content-Type' => 'text/html'}, ["Board #{board} not found."]]
        end
      end
    end
  end
end
