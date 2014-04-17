module Hike
  module FileUtils
    extend self

    # Like `File.stat`. Returns nil if the file does not exist.
    def stat(path)
      if File.exist?(path)
        File.stat(path.to_s)
      else
        nil
      end
    end

    # A version of `Dir.entries` that filters out `.` files and `~` swap files.
    # Returns an empty `Array` if the directory does not exist.
    def entries(path)
      if File.directory?(path)
        Dir.entries(path).reject { |entry| entry =~ /^\.|~$|^\#.*\#$/ }.sort
      else
        []
      end
    end
  end
end
