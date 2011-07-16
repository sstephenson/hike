require 'pathname'

module Hike
  # `Index` is an internal cached variant of `Trail`. It assumes the
  # file system does not change between `find` calls. All `stat` and
  # `entries` calls are cached for the lifetime of the `Index` object.
  class Index
    # `Index#paths` is an immutable `Paths` collection.
    attr_reader :paths

    # `Index#extensions` is an immutable `Extensions` collection.
    attr_reader :extensions

    # `Index.new` is an internal method. Instead of constructing it
    # directly, create a `Trail` and call `Trail#index`.
    def initialize(root, paths, extensions)
      @root = root

      # Freeze is used here so an error is throw if a mutator method
      # is called on the array. Mutating `@paths` or `@extensions`
      # would have unpredictable results.
      @paths      = paths.dup.freeze
      @extensions = extensions.dup.freeze
      @pathnames  = paths.map { |path| Pathname.new(path) }

      @stats    = {}
      @entries  = {}
      @patterns = {}
    end

    # `Index#root` returns root path as a `String`. This attribute is immutable.
    def root
      @root.to_s
    end

    # `Index#index` returns `self` to be compatable with the `Trail` interface.
    def index
      self
    end

    # The real implementation of `find`. `Trail#find` generates a one
    # time index and delegates here.
    #
    # See `Trail#find` for usage.
    def find(*logical_paths, &block)
      if block_given?
        options = extract_options!(logical_paths)
        base_path = Pathname.new(options[:base_path] || @root)

        logical_paths.each do |logical_path|
          logical_path = Pathname.new(logical_path.sub(/^\//, ''))

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

    # A cached version of `Dir.entries` that filters out `.` files and
    # `~` swap files. Returns an empty `Array` if the directory does
    # not exist.
    def entries(path)
      key = path.to_s
      @entries[key] ||= Pathname.new(path).entries.reject { |entry| entry.to_s =~ /^\.|~$|^\#.*\#$/ }
    rescue Errno::ENOENT
      @entries[key] = []
    end

    # A cached version of `File.stat`. Returns nil if the file does
    # not exist.
    def stat(path)
      key = path.to_s
      if @stats.key?(key)
        @stats[key]
      else
        begin
          @stats[key] = File.stat(path)
        rescue Errno::ENOENT
          @stats[key] = nil
        end
      end
    end

    protected
      def extract_options!(arguments)
        arguments.last.is_a?(Hash) ? arguments.pop.dup : {}
      end

      def relative?(logical_path)
        logical_path.to_s =~ /^\.\.?\//
      end

      # Finds logical path across all `paths`
      def find_in_paths(logical_path, &block)
        dirname, basename = logical_path.split
        @pathnames.each do |base_path|
          match(base_path.join(dirname), basename, &block)
        end
      end

      # Finds relative logical path, `../test/test_trail`. Requires a
      # `base_path` for reference.
      def find_in_base_path(logical_path, base_path, &block)
        candidate = base_path.join(logical_path)
        dirname, basename = candidate.split
        match(dirname, basename, &block) if paths_contain?(dirname)
      end

      # Checks if the path is actually on the file system and performs
      # any syscalls if necessary.
      def match(dirname, basename)
        # Potential `entries` syscall
        matches = entries(dirname)

        pattern = pattern_for(basename)
        matches = matches.select { |m| m.to_s =~ pattern }

        sort_matches(matches, basename).each do |path|
          pathname = dirname.join(path)

          # Potential `stat` syscall
          stat = stat(pathname)

          # Exclude directories
          if stat && stat.file?
            yield pathname.to_s
          end
        end
      end

      # Returns true if `dirname` is a subdirectory of any of the `paths`
      def paths_contain?(dirname)
        paths.any? { |path| dirname.to_s[0, path.length] == path }
      end

      # Returns a `Regexp` that matches the allowed extensions.
      #
      #     pattern_for("index.html") #=> /^index.html(.builder|.erb)+$/
      def pattern_for(basename)
        @patterns[basename] ||= begin
          extension_pattern = extensions.map { |e| Regexp.escape(e) }.join("|")
          /^#{Regexp.escape(basename.to_s)}(?:#{extension_pattern}|)+$/
        end
      end

      # Sorts candidate matches by their extension
      # priority. Extensions in the front of the `extensions` carry
      # more weight.
      def sort_matches(matches, basename)
        matches.sort_by do |match|
          extnames = match.to_s[basename.to_s.length..-1].scan(/.[^.]+/)
          extnames.inject(0) { |sum, ext| sum + extensions.index(ext) + 1 }
        end
      end
  end
end
