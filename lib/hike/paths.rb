require 'pathname'

module Hike
  class Paths < NormalizedArray
    def initialize(root = ".")
      @root = root
      super()
    end

    def normalize_element(path)
      pathname = Pathname.new(path)
      path = File.join(@root, path) if pathname.relative?
      File.expand_path(path)
    end
  end
end
