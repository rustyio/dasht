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

    def plugins_path
      File.join(File.dirname(__FILE__), "..", "..", "plugins")
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

    def load_system_plugins
      s = ""
      Dir[File.join(plugins_path, "*.html")].each do |path|
        name = File.basename(path).gsub(".html", "")
        s += "<script id='#{name}-template' type='x-tmpl-mustache'>\n"
        s += IO.read(path)
        s += "</script>\n"
      end

      Dir[File.join(plugins_path, "*.js")].each do |path|
        s += "<script>\n"
        s += IO.read(path)
        s += "</script>\n"
      end
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
