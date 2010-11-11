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
      dirname = File.expand_path(dirname)
      @entries[dirname] ||= if File.directory?(dirname)
        Dir.entries(dirname).reject do |entry|
          entry =~ /^\.\.?$/
        end.sort
      else
        []
      end
    end

    def files(dirname)
      dirname = File.expand_path(dirname)
      @files[dirname] ||= entries(dirname).select do |entry|
        File.file?(File.join(dirname, entry))
      end
    end
  end
end
