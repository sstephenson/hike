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
      index.expire_mtimes

      logical_paths.each do |logical_path|
        if result = find_path(logical_path)
          return File.expand_path(result)
        end
      end
      nil
    end

    protected
      attr_reader :index

      def find_path(logical_path)
        dirname, basename = File.split(logical_path)
        pattern = filename_pattern_for(basename)

        paths.each do |root|
          path = File.join(root, dirname)
          matches = match_files_in(path, pattern)
          return File.join(path, match_from(matches, basename)) unless matches.empty?
        end
        nil
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
