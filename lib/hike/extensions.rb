require 'hike/normalized_array'

module Hike
  class Extensions < NormalizedArray
    def normalize_element(extension)
      if extension[/^\./]
        extension
      else
        ".#{extension}"
      end
    end
  end
end
