module Hike
  class Trail
    attr_reader :root, :paths, :extensions

    def initialize(root = ".")
      @root = File.expand_path(root)
      @index = DirectoryIndex.new
      @paths = Paths.new(@root)
      @extensions = Extensions.new
    end

    def find(*logical_paths)
      options = logical_paths.last.is_a?(Hash) ? logical_paths.pop : {}
      if relative_to = options[:relative_to]
        base_path = File.dirname(relative_to)
      end

      reset!

      searching(logical_paths) do |logical_path|
        if relative_to
          find_in_base_path(logical_path, base_path)
        else
          find_in_paths(logical_path)
        end
      end
    end

    protected
      def reset!
        @index.expire_cache
        @patterns = {}
      end

      def find_in_paths(logical_path)
        dirname, basename = File.split(logical_path)
        searching(paths) do |base_path|
          match(File.join(base_path, dirname), basename)
        end
      end

      def find_in_base_path(logical_path, base_path)
        candidate = File.expand_path(File.join(base_path, logical_path))
        dirname, basename = File.split(candidate)
        match(dirname, basename) if paths_contain?(dirname)
      end

      def match(dirname, basename)
        matches = @index.files(dirname).grep(pattern_for(basename))
        unless matches.empty?
          path = select_match_from(matches, basename)
          File.expand_path(File.join(dirname, path))
        end
      end

      def paths_contain?(dirname)
        paths.any? { |path| dirname[0, path.length] == path }
      end

      def pattern_for(basename)
        @patterns[basename] ||= begin
          extension_pattern = extensions.map { |e| Regexp.escape(e) }.join("|")
          /^#{Regexp.escape(basename)}(?:#{extension_pattern}|)+$/
        end
      end

      def select_match_from(matches, basename)
        if matches.length == 1
          matches.first
        elsif matches.length > 1
          select_ordered_match_from(matches, basename)
        end
      end

      def select_ordered_match_from(matches, basename)
        matches.sort_by do |match|
          extnames = match[basename.length..-1].scan(/.[^.]+/)
          extnames.inject(0) { |sum, ext| sum + extensions.index(ext) + 1 }
        end.first
      end

      def searching(collection)
        collection.each do |value|
          if result = yield(value)
            return result
          end
        end
        nil
      end
  end
end
