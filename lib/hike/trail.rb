module Hike
  class Trail
    attr_reader :root, :paths, :extensions

    def initialize(root = ".")
      @root = File.expand_path(root)
      @index = DirectoryIndex.new
      @paths = Paths.new(@root)
      @extensions = Extensions.new
    end

    def find(*logical_paths, &block)
      if block_given?
        options = extract_options!(logical_paths)
        base_path = options[:base_path] || root
        reset!

        logical_paths.each do |logical_path|
          if relative?(logical_path)
            find_in_base_path(logical_path, base_path, &block)
          else
            find_in_paths(logical_path, &block)
          end
        end

        nil
      else
        find(*logical_paths) do |path|
          return path
        end
      end
    end

    protected
      def reset!
        @index.expire_cache
        @patterns = {}
      end

      def extract_options!(arguments)
        arguments.last.is_a?(Hash) ? arguments.pop : {}
      end

      def relative?(logical_path)
        logical_path =~ /^\.\.?\//
      end

      def find_in_paths(logical_path, &block)
        dirname, basename = File.split(logical_path)
        paths.each do |base_path|
          match(File.join(base_path, dirname), basename, &block)
        end
      end

      def find_in_base_path(logical_path, base_path, &block)
        candidate = File.expand_path(File.join(base_path, logical_path))
        dirname, basename = File.split(candidate)
        match(dirname, basename, &block) if paths_contain?(dirname)
      end

      def match(dirname, basename)
        matches = @index.files(dirname).grep(pattern_for(basename))
        sort_matches(matches, basename).each do |path|
          yield File.expand_path(File.join(dirname, path))
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

      def sort_matches(matches, basename)
        matches.sort_by do |match|
          extnames = match[basename.length..-1].scan(/.[^.]+/)
          extnames.inject(0) { |sum, ext| sum + extensions.index(ext) + 1 }
        end
      end
  end
end
