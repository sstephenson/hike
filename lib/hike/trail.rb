require 'pathname'
require 'hike/cached_trail'
require 'hike/extensions'
require 'hike/paths'

module Hike
  # `Trail` is the public container class for holding paths and extensions.
  class Trail
    include FileUtils

    # `Trail#paths` is a mutable `Paths` collection.
    #
    #     trail = Hike::Trail.new
    #     trail.paths.push "~/Projects/hike/lib", "~/Projects/hike/test"
    #
    # The order of the paths is significant. Paths in the beginning of
    # the collection will be checked first. In the example above,
    # `~/Projects/hike/lib/hike.rb` would shadow the existent of
    # `~/Projects/hike/test/hike.rb`.
    attr_reader :paths

    # `Trail#extensions` is a mutable `Extensions` collection.
    #
    #     trail = Hike::Trail.new
    #     trail.paths.push "~/Projects/hike/lib"
    #     trail.extensions.push ".rb"
    #
    # Extensions allow you to find files by just their name omitting
    # their extension. Is similar to Ruby's require mechanism that
    # allows you to require files with specifiying `foo.rb`.
    attr_reader :extensions

    # `Trail#aliases` is a mutable `Hash` mapping an extension to
    # an `Array` of aliases.
    #
    #   trail = Hike::Trail.new
    #   trail.paths.push "~/Projects/hike/site"
    #   trail.aliases['.htm']   = 'html'
    #   trail.aliases['.xhtml'] = 'html'
    #   trail.aliases['.php']   = 'html'
    #
    # Aliases provide a fallback when the primary extension is not
    # matched. In the example above, a lookup for "foo.html" will
    # check for the existence of "foo.htm", "foo.xhtml", or "foo.php".
    attr_reader :aliases

    # A Trail accepts an optional root path that defaults to your
    # current working directory. Any relative paths added to
    # `Trail#paths` will expanded relative to the root.
    def initialize(root = ".")
      @root       = Pathname.new(root).expand_path
      @paths      = Paths.new(@root)
      @extensions = Extensions.new
      @aliases    = {}
    end

    # `Trail#root` returns root path as a `String`. This attribute is immutable.
    def root
      @root.to_s
    end

    # Prepend `path` to `Paths` collection
    def prepend_paths(*paths)
      self.paths.unshift(*paths)
    end
    alias_method :prepend_path, :prepend_paths

    # Append `path` to `Paths` collection
    def append_paths(*paths)
      self.paths.push(*paths)
    end
    alias_method :append_path, :append_paths

    # Remove `path` from `Paths` collection
    def remove_path(path)
      self.paths.delete(path)
    end

    # Prepend `extension` to `Extensions` collection
    def prepend_extensions(*extensions)
      self.extensions.unshift(*extensions)
    end
    alias_method :prepend_extension, :prepend_extensions

    # Append `extension` to `Extensions` collection
    def append_extensions(*extensions)
      self.extensions.push(*extensions)
    end
    alias_method :append_extension, :append_extensions

    # Remove `extension` from `Extensions` collection
    def remove_extension(extension)
      self.extensions.delete(extension)
    end

    # Alias `new_extension` to `old_extension`
    def alias_extension(new_extension, old_extension)
      aliases[normalize_extension(new_extension)] = normalize_extension(old_extension)
    end

    # Remove the alias for `extension`
    def unalias_extension(extension)
      aliases.delete(normalize_extension(extension))
    end

    # `Trail#find` returns a the expand path for a logical path in the
    # path collection.
    #
    #     trail = Hike::Trail.new "~/Projects/hike"
    #     trail.extensions.push ".rb"
    #     trail.paths.push "lib", "test"
    #
    #     trail.find "hike/trail"
    #     # => "~/Projects/hike/lib/hike/trail.rb"
    #
    #     trail.find "test_trail"
    #     # => "~/Projects/hike/test/test_trail.rb"
    #
    # `find` accepts multiple fallback logical paths that returns the
    # first match.
    #
    #     trail.find "hike", "hike/index"
    #
    # is equivalent to
    #
    #     trail.find("hike") || trail.find("hike/index")
    #
    def find(*args)
      index.find(*args)
    end

    # `Trail#find_all` returns all matching paths including fallbacks and
    #  shadowed matches.
    #
    #     trail.find_all("hike", "hike/index").each { |path| warn path }
    #
    # `find_all` returns an `Enumerator`. This allows you to filter your
    # matches by any condition.
    #
    #     trail.find_all("application").find do |path|
    #       mime_type_for(path) == "text/css"
    #     end
    #
    def find_all(*args, &block)
      cached.find_all(*args, &block)
    end

    # `Trail#cached` returns an `CachedTrail` object that has the same
    # interface as `Trail`. An `CachedTrail` is a cached `Trail` object that
    # does not update when the file system changes. If you are
    # confident that you are not making changes the paths you are
    # searching, `cached` will avoid excess system calls.
    #
    #     cached = trail.cached
    #     cached.find "hike/trail"
    #     cached.find "test_trail"
    #
    def cached
      CachedTrail.new(root, paths, extensions, aliases)
    end

    # Deprecated alias for `cached`.
    alias_method :index, :cached

    private
      def normalize_extension(extension)
        if extension[/^\./]
          extension
        else
          ".#{extension}"
        end
      end
  end
end
