module Dasht
  class Board
    attr_accessor :parent
    attr_accessor :name
    attr_accessor :tiles

    def initialize(parent, name)
      @parent = parent
      @name  = name
      @tiles = []

      # Load the erb.
      path = File.join(File.dirname(__FILE__), "..", "..", "views", "dashboard.erb")
      @erb = ERB.new(IO.read(path))
    end

    def method_missing(method, *args, &block)
      @tiles << [method, *args]
    end

    def to_html
      @erb.result
    end
  end
end
