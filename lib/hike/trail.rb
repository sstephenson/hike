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
          return result
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
        extension_pattern += "|" if has_registered_extension?(basename)
        /^#{Regexp.escape(basename)}(?:#{extension_pattern})$/
      end

      def match_from(matches, basename)
        if matches.length == 1
          matches.first
        elsif matches.length > 1
          ordered_match_from(matches, basename)
        end
      end

      def ordered_match_from(matches, basename)
        extensions.each do |extension|
          candidate = basename + extension
          return candidate if matches.include?(candidate)
        end
        basename
      end

      def has_registered_extension?(logical_path)
        extensions.include?(File.extname(logical_path))
      end
  end
end
