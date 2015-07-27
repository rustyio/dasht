module Dasht
  class Board
    attr_accessor :parent
    attr_accessor :name
    attr_accessor :tiles

    def initialize(parent, name)
      @parent = parent
      @name  = name
      @tiles = []
    end

    def views_path
      File.join(File.dirname(__FILE__), "..", "..", "views")
    end

    def to_html
      # Load the erb.
      path = File.join(views_path, "dashboard.erb")
      @erb = ERB.new(IO.read(path))
      @erb.result(_binding do |*args| _handle_yield(*args) end)
    end

    def _binding
      binding
    end

    def _handle_yield(*args)
      s = "<script>\n"
      @tiles.map do |options|
        s += "add_tile(#{options.to_json});\n"
      end
      s += "</script>\n"
      s
    end

    def method_missing(method, *args, &block)
      metric = args.shift
      options = args.pop
      @tiles << {
        :type       => method,
        :metric     => metric,
        :resolution => 60,
        :refresh    => 1,
        :width      => 1,
        :height     => 1,
        :extra_args => args
      }.merge(options)
    end
  end
end
