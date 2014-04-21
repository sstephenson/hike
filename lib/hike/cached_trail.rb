module Hike
  # `CachedTrail` is an internal cached variant of `Trail`. It assumes the
  # file system does not change between `find` calls. All `stat` and
  # `entries` calls are cached for the lifetime of the `CachedTrail` object.
  class CachedTrail
    include FileUtils

    # `CachedTrail#paths` is an immutable `Paths` collection.
    attr_reader :paths

    # `CachedTrail#extensions` is an immutable `Extensions` collection.
    attr_reader :extensions

    # `CachedTrail#aliases` is an immutable `Hash` mapping an extension to
    # an `Array` of aliases.
    attr_reader :aliases

    # `CachedTrail.new` is an internal method. Instead of constructing it
    # directly, create a `Trail` and call `Trail#CachedTrail`.
    def initialize(root, paths, extensions, aliases)
      @root = root.to_s

      # Freeze is used here so an error is throw if a mutator method
      # is called on the array. Mutating `@paths`, `@extensions`, or
      # `@aliases` would have unpredictable results.
      @paths      = paths.dup.freeze
      @extensions = extensions.dup.freeze

      # Create a reverse mapping from extension to possible aliases.
      @aliases = aliases.dup.freeze
      @reverse_aliases = @aliases.inject({}) { |h, (k, a)|
        (h[a] ||= []) << k; h
      }

      @stats    = Hash.new { |h, k| h[k] = FileUtils.stat(k) }
      @entries  = Hash.new { |h, k| h[k] = FileUtils.entries(k) }
      @patterns = Hash.new { |h, k| h[k] = pattern_for(k) }
    end

    # `CachedTrail#root` returns root path as a `String`. This attribute is immutable.
    attr_reader :root

    # `CachedTrail#cached` returns `self` to be compatable with the `Trail` interface.
    def cached
      self
    end

    # Deprecated alias for `cached`.
    alias_method :index, :cached

    # The real implementation of `find`. `Trail#find` generates a one
    # time cache and delegates here.
    #
    # See `Trail#find` for usage.
    def find(*logical_paths)
      find_all(*logical_paths).first
    end

    # The real implementation of `find_all`. `Trail#find_all` generates a one
    # time index and delegates here.
    #
    # See `Trail#find_all` for usage.
    def find_all(*logical_paths, &block)
      return to_enum(__method__, *logical_paths) unless block_given?

      options = extract_options!(logical_paths)
      base_path = (options[:base_path] || root).to_s

      logical_paths.each do |logical_path|
        logical_path = logical_path.sub(/^\//, '')

        if relative?(logical_path)
          find_in_base_path(logical_path, base_path, &block)
        else
          find_in_paths(logical_path, &block)
        end
      end

      nil
    end

    # A cached version of `Dir.entries` that filters out `.` files and
    # `~` swap files. Returns an empty `Array` if the directory does
    # not exist.
    def entries(path)
      @entries[path]
    end

    # A cached version of `File.stat`. Returns nil if the file does
    # not exist.
    def stat(path)
      @stats[path]
    end

    protected
      def extract_options!(arguments)
        arguments.last.is_a?(Hash) ? arguments.pop.dup : {}
      end

      def relative?(path)
        path =~ /^\.\.?\//
      end

      # Finds logical path across all `paths`
      def find_in_paths(logical_path, &block)
        dirname, basename = File.split(logical_path)
        @paths.each do |base_path|
          match(File.expand_path(dirname, base_path), basename, &block)
        end
      end

      # Finds relative logical path, `../test/test_trail`. Requires a
      # `base_path` for reference.
      def find_in_base_path(logical_path, base_path, &block)
        candidate = File.expand_path(logical_path, base_path)
        dirname, basename = File.split(candidate)
        match(dirname, basename, &block) if paths_contain?(dirname)
      end

      # Checks if the path is actually on the file system and performs
      # any syscalls if necessary.
      def match(dirname, basename)
        # Potential `entries` syscall
        matches = @entries[dirname]

        pattern = @patterns[basename]
        matches = matches.select { |m| m =~ pattern }

        sort_matches(matches, basename).each do |path|
          filename = File.join(dirname, path)

          # Potential `stat` syscall
          stat = @stats[filename]

          # Exclude directories
          if stat && stat.file?
            yield filename
          end
        end
      end

      # Returns true if `dirname` is a subdirectory of any of the `paths`
      def paths_contain?(dirname)
        paths.any? { |path| dirname[0, path.length] == path }
      end

      # Returns a `Regexp` that matches the allowed extensions.
      #
      #     pattern_for("index.html") #=> /^index(.html|.htm)(.builder|.erb)*$/
      def pattern_for(basename)
        extname = File.extname(basename)
        aliases = @reverse_aliases[extname]

        if aliases
          basename = File.basename(basename, extname)
          aliases  = [extname] + aliases
          aliases_pattern = aliases.map { |e| Regexp.escape(e) }.join("|")
          basename_re = Regexp.escape(basename) + "(?:#{aliases_pattern})"
        else
          basename_re = Regexp.escape(basename)
        end

        extension_pattern = extensions.map { |e| Regexp.escape(e) }.join("|")
        /^#{basename_re}(?:#{extension_pattern})*$/
      end

      # Sorts candidate matches by their extension
      # priority. Extensions in the front of the `extensions` carry
      # more weight.
      def sort_matches(matches, basename)
        extname = File.extname(basename)
        aliases = @reverse_aliases[extname] || []

        matches.sort_by do |match|
          extnames = match.sub(basename, '').scan(/\.[^.]+/)
          extnames.inject(0) do |sum, ext|
            if i = extensions.index(ext)
              sum + i + 1
            elsif i = aliases.index(ext)
              sum + i + 11
            else
              sum
            end
          end
        end
      end
  end
end
