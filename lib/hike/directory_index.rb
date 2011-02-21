require 'pathname'

module Hike
  class DirectoryIndex
    def initialize
      expire_cache
    end

    def expire_cache
      @entries = {}
      @files = {}
      true
    end

    def entries(dirname)
      dirname = Pathname.new(dirname).expand_path
      @entries[dirname] ||= if dirname.directory?
        dirname.entries.reject do |entry|
          entry.to_s =~ /^\.\.?$/
        end.sort
      else
        []
      end
    end

    def files(dirname)
      dirname = Pathname.new(dirname).expand_path
      @files[dirname] ||= entries(dirname).select do |entry|
        dirname.join(entry).file?
      end.map(&:to_s)
    end
  end
end
