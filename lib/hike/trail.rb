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

      index.expire_cache

      logical_paths.each do |logical_path|
        if relative_to
          result = find_path_relative(logical_path, base_path)
        else
          result = find_path(logical_path)
        end

        return File.expand_path(result) if result
      end
      nil
    end

    protected
      attr_reader :index

      def find_path(logical_path)
        dirname, basename = File.split(logical_path)
        pattern = filename_pattern_for(basename)

        paths.each do |base_path|
          if path = find_in_base(File.join(base_path, dirname), basename, pattern)
            return path
          end
        end
        nil
      end

      def find_path_relative(logical_path, base_path)
        dirname, basename = File.split(File.join(base_path, logical_path))
        dirname = File.expand_path(dirname)
        pattern = filename_pattern_for(basename)

        if paths.any? { |path| dirname[0, path.length] == path }
          find_in_base(File.expand_path(dirname), basename, pattern)
        end
      end

      def find_in_base(base_path, base_name, pattern)
        matches = match_files_in(base_path, pattern)
        File.join(base_path, match_from(matches, base_name)) unless matches.empty?
      end

      def match_files_in(dirname, pattern)
        index.files(dirname).grep(pattern)
      end

      def filename_pattern_for(basename)
        extension_pattern = extensions.map { |e| Regexp.escape(e) }.join("|")
        /^#{Regexp.escape(basename)}(?:#{extension_pattern}|)+$/
      end

      def match_from(matches, basename)
        if matches.length == 1
          matches.first
        elsif matches.length > 1
          ordered_match_from(matches, basename)
        end
      end

      def ordered_match_from(matches, basename)
        matches.sort_by do |match|
          extnames = match[basename.length..-1].scan(/.[^.]+/)
          extnames.inject(0) { |sum, ext| sum + extensions.index(ext) + 1 }
        end.first
      end
  end
end
