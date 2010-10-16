module Hike
  class Trail
    attr_reader :root, :paths, :extensions

    def initialize(root)
      @root = File.expand_path(root)
      @paths = Paths.new(@root)
      @extensions = Extensions.new
    end

    def find(logical_path)
      candidates = candidates_for(logical_path)

      paths.each do |path|
        candidates.each do |candidate|
          filename = File.join(path, candidate)
          return filename if exists?(filename)
        end
      end

      nil
    end

    protected
      def candidates_for(logical_path)
        candidates = extensions.map { |ext| logical_path + ext }
        candidates.unshift(logical_path) if has_extension?(logical_path)
        candidates
      end

      def has_extension?(logical_path)
        extensions.include?(File.extname(logical_path))
      end

      def exists?(path)
        File.exists?(path)
      end
  end
end
