module Dasht
  class Board
    attr_accessor :parent
    attr_accessor :name
    attr_accessor :tiles
    attr_accessor :background
    attr_accessor :default_resolution
    attr_accessor :default_refresh
    attr_accessor :default_width
    attr_accessor :default_height

    def initialize(parent, name)
      @parent = parent
      @name  = name
      @tiles = []
    end

    def to_html
      # Load the erb.
      path = File.join(parent.views_path, "dashboard.erb")
      @erb = ERB.new(IO.read(path))
      @erb.result(binding)
    end

    def emit_plugin_css
      _emit_css(parent.system_plugins_path)
    end

    def emit_plugin_html
      _emit_html(parent.system_plugins_path)
    end

    def emit_plugin_js
      _emit_js(parent.system_plugins_path)
    end

    def method_missing(method, *args, &block)
      begin
        metric = args.shift
        options = args.pop || {}
        @tiles << {
          :type       => method,
          :metric     => metric,
          :resolution => self.default_resolution || parent.default_resolution || 60,
          :refresh    => self.default_refresh    || parent.default_refresh    || 5,
          :width      => self.default_width      || parent.default_width      || 3,
          :height     => self.default_height     || parent.default_height     || 3,
          :extra_args => args
        }.merge(options)
      rescue => e
        super(method, *args, &block)
      end
    end

    private

    def emit_tile_js
      s = "<script>\n"
      s += "$(function() {\n";
      @tiles.map do |options|
        s += "Dasht.add_tile(#{options.to_json});\n"
      end
      s += "});"
      s += "</script>\n"
      s
    end

    def emit_board_js
      s = "<script>"
      if background = self.background || parent.background
        s += "$('body').css('background', #{background.to_json});\n"
      end
      s += "</script>\n"
      s
    end

    def _emit_css(plugin_path)
      s = ""
      Dir[File.join(plugin_path, "*.css")].each do |path|
        name = File.basename(path)
        s += "<link rel='stylesheet' type='text/css' href='/assets/plugins/#{name}'>\n"
      end
      return s
    end

    def _emit_html(plugin_path)
      s = ""
      Dir[File.join(plugin_path, "*.html")].each do |path|
        name = File.basename(path).gsub(".html", "")
        s += "<script id='#{name}-template' type='x-tmpl-mustache'>\n"
        s += "<div class='tile #{name}-tile width-{{width}} height-{{height}}'>\n"
        s += IO.read(path)
        s += "</div>\n"
        s += "</script>\n"
      end
      return s
    end

    def _emit_js(plugin_path)
      s = ""
      Dir[File.join(plugin_path, "*.js")].each do |path|
        name = File.basename(path)
        s += "<script src='/assets/plugins/#{name}'></script>\n"
      end
      s
    end
  end
end
