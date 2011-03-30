require 'pathname'
require 'hike/normalized_array'

module Hike
  class Paths < NormalizedArray
    def initialize(root = ".")
      @root = Pathname.new(root)
      super()
    end

    def normalize_element(path)
      path = Pathname.new(path)
      path = @root.join(path) if path.relative?
      path.expand_path.to_s
    end
  end
end
