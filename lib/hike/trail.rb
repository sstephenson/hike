require 'pathname'
require 'hike/extensions'
require 'hike/paths'

module Hike
  class Trail
    attr_reader :paths, :extensions

    def initialize(root = ".")
      @root = Pathname.new(root).expand_path
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

        options[:directories] ||= false

        options[:stat_cache]     = {}
        options[:entries_cache]  = {}
        options[:patterns_cache] = {}

        logical_paths.each do |logical_path|
          logical_path = Pathname.new(logical_path.sub(/^\//, ''))

          if relative?(logical_path)
            find_in_base_path(logical_path, base_path, options, &block)
          else
            find_in_paths(logical_path, options, &block)
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
      def extract_options!(arguments)
        arguments.last.is_a?(Hash) ? arguments.pop.dup : {}
      end

      def relative?(logical_path)
        logical_path.to_s =~ /^\.\.?\//
      end

      def pathnames
        paths.map { |path| Pathname.new(path) }
      end

      def find_in_paths(logical_path, options, &block)
        dirname, basename = logical_path.split
        pathnames.each do |base_path|
          match(base_path.join(dirname), basename, options, &block)
        end
      end

      def find_in_base_path(logical_path, base_path, options, &block)
        candidate = base_path.join(logical_path)
        dirname, basename = candidate.split
        match(dirname, basename, options, &block) if paths_contain?(dirname)
      end

      def match(dirname, basename, options)
        matches = entries(options[:entries_cache], dirname)

        pattern = pattern_for(options[:patterns_cache], basename)
        matches = matches.select { |m| m.to_s =~ pattern }

        cache = options[:stat_cache]
        sort_matches(matches, basename).each do |path|
          pathname = dirname.join(path)

          if options[:directories]
            yield pathname.to_s
          elsif (stat = self.stat(cache, pathname)) && stat.file?
            yield pathname.to_s
          end
        end
      end

      def stat(cache, pathname)
        if cache.key?(pathname)
          cache[pathname]
        else
          begin
            cache[pathname] = pathname.stat
          rescue Errno::ENOENT
            cache[pathname] = nil
          end
        end
      end

      def entries(cache, pathname)
        cache[pathname] ||= pathname.entries.reject { |entry| entry.to_s =~ /^\.\.?$/ }
      rescue Errno::ENOENT
        cache[pathname] = []
      end

      def paths_contain?(dirname)
        paths.any? { |path| dirname.to_s[0, path.to_s.length] == path }
      end

      def pattern_for(cache, basename)
        cache[basename] ||= begin
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
