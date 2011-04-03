require 'pathname'
require 'hike/extensions'
require 'hike/index'
require 'hike/paths'

module Hike
  class Trail
    attr_reader :paths, :extensions

    def initialize(root = ".")
      @root       = Pathname.new(root).expand_path
      @paths      = Paths.new(@root)
      @extensions = Extensions.new
    end

    def root
      @root.to_s
    end

    def index
      Index.new(root, paths, extensions)
    end

    def find(*args, &block)
      index.find(*args, &block)
    end
  end
end
