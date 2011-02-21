require 'pathname'

module Hike
  class Trail
    attr_reader :paths, :extensions

    def initialize(root = ".")
      @root = Pathname.new(root).expand_path
      @index = DirectoryIndex.new
      @paths = Paths.new(@root)
      @extensions = Extensions.new
    end

    def root
      @root.to_s
    end

    def find(*logical_paths, &block)
      if block_given?
        options = extract_options!(logical_paths)
        base_path = Pathname.new(options[:base_path] || @root)
        reset!

        logical_paths.each do |logical_path|
          logical_path = Pathname.new(logical_path)
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
        logical_path.to_s =~ /^\.\.?\//
      end

      def pathnames
        paths.map { |path| Pathname.new(path) }
      end

      def find_in_paths(logical_path, &block)
        dirname, basename = logical_path.split
        pathnames.each do |base_path|
          match(base_path.join(dirname), basename, &block)
        end
      end

      def find_in_base_path(logical_path, base_path, &block)
        candidate = base_path.join(logical_path).expand_path
        dirname, basename = candidate.split
        match(dirname, basename, &block) if paths_contain?(dirname)
      end

      def match(dirname, basename)
        matches = @index.files(dirname).grep(pattern_for(basename))
        matches = matches.map { |f| Pathname.new(f) }
        sort_matches(matches, basename).each do |path|
          yield dirname.join(path).expand_path.to_s
        end
      end

      def paths_contain?(dirname)
        paths.any? { |path| dirname.to_s[0, path.to_s.length] == path }
      end

      def pattern_for(basename)
        @patterns[basename] ||= begin
          extension_pattern = extensions.map { |e| Regexp.escape(e) }.join("|")
          /^#{Regexp.escape(basename.to_s)}(?:#{extension_pattern}|)+$/
        end
      end

      def sort_matches(matches, basename)
        matches.sort_by do |match|
          extnames = match.to_s[basename.to_s.length..-1].scan(/.[^.]+/)
          extnames.inject(0) { |sum, ext| sum + extensions.index(ext) + 1 }
        end
      end
  end
end
