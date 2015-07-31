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
          :resolution => 60,
          :refresh    => 1,
          :width      => 1,
          :height     => 1,
          :fontsize   => :medium,
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
        s += "add_tile(#{options.to_json});\n"
      end
      s += "});"
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
        s += "<div class='tile #{name}-tile width-{{width}} height-{{height}} fontsize-{{fontsize}}'>\n"
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
