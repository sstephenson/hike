module Hike
  class Paths < NormalizedArray
    def initialize(root = ".")
      @root = root
      super()
    end

    def normalize_element(path)
      path = File.join(@root, path) unless path[/^\//]
      File.expand_path(path)
    end
  end
end
