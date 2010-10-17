module Hike
  class DirectoryIndex
    def initialize
      expire
    end

    def expire
      expire_mtimes
      expire_files
    end

    def expire_mtimes
      @mtimes = {}
      true
    end

    def expire_files
      @files = {}
      true
    end

    def mtime(dirname)
      @mtimes[dirname] ||= File.directory?(dirname) && File.mtime(dirname)
    end

    def files(dirname)
      if current_mtime = mtime(dirname)
        cached_mtime, files = @files[dirname]
        if current_mtime == cached_mtime
          return files
        else
          files = Dir.entries(dirname).select do |entry|
            File.file?(File.join(dirname, entry))
          end
        end
      else
        files = []
      end

      @files[dirname] = [current_mtime, files]
      files
    end
  end
end
