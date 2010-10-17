module Hike
  class Trail
    attr_reader :root, :paths, :extensions

    def initialize(root)
      @root = File.expand_path(root)
      @index = DirectoryIndex.new
      @paths = Paths.new(@root)
      @extensions = Extensions.new
    end

    def find(*logical_paths)
      @index.expire_mtimes
      candidates = candidates_for_paths(logical_paths)

      paths.each do |path|
        candidates.each do |candidate|
          filename = File.join(path, candidate)
          return filename if exists?(filename)
        end
      end

      nil
    end

    protected
      def candidates_for_paths(logical_paths)
        logical_paths.map do |logical_path|
          candidates_for_path(logical_path)
        end.flatten
      end

      def candidates_for_path(logical_path)
        candidates = extensions.map { |ext| logical_path + ext }
        candidates.unshift(logical_path) if has_extension?(logical_path)
        candidates
      end

      def has_extension?(logical_path)
        extensions.include?(File.extname(logical_path))
      end

      def exists?(path)
        dirname, basename = File.dirname(path), File.basename(path)
        @index.files(dirname).include?(basename)
      end
  end
end
