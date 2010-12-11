require 'pathname'
module Hike
  class Paths < NormalizedArray
    def initialize(root = ".")
      @root = root
      super()
    end
    
    def normalize_element(path)
        path = File.join(@root, path) unless Pathname.new(path.split(File::SEPARATOR)[0]+File::SEPARATOR).root?
      File.expand_path(path)
    end
  end
end
