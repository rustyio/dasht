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
      @tiles.map do |tile_options|
        s += "add_tile(#{tile_options.to_json});\n"
      end
      s += "</script>\n"
      s
    end

    def value(metric, options = {})
      @tiles << options.merge({
                                :type => :value,
                                :metric => metric
      })
    end
  end
end
