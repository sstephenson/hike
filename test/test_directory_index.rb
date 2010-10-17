require "hike_test"
require "fileutils"

class DirectoryIndexTest < Test::Unit::TestCase
  def setup
    @root = File.join(FIXTURE_ROOT, "tmp")
    @index = Hike::DirectoryIndex.new
    @mtime = Time.now - 1

    FileUtils.mkdir_p @root
    FileUtils.mkdir_p File.join(@root, "baz")
    touch "foo.txt", @mtime
    touch "bar.txt", @mtime
    touch nil, @mtime
  end

  def teardown
    FileUtils.rm_rf @root
  end

  def touch(filename, timestamp = Time.now)
    if filename
      path = fixture_path(filename)
      FileUtils.touch(path)
    else
      path = @root
    end
    File.utime(timestamp, timestamp, path)
  end

  def fixture_path(path)
    File.join(@root, path)
  end

  def test_mtime
    assert_equal @mtime.to_i, @index.mtime(@root).to_i
    assert_equal false, @index.mtime(fixture_path("foo.txt"))
    assert_equal false, @index.mtime(fixture_path("nonexistent"))
  end

  def test_files
    assert_equal ["bar.txt", "foo.txt"], @index.files(@root).sort
    assert_equal [], @index.files(fixture_path("foo.txt"))
    assert_equal [], @index.files(fixture_path("nonexistent"))
  end

  def test_mtime_is_cached
    mtime = @index.mtime(@root)
    touch "baz.txt"
    assert_equal mtime, @index.mtime(@root)
  end

  def test_files_are_cached
    files = @index.files(@root)
    touch "baz.txt"
    assert_equal files, @index.files(@root)
  end

  def test_expiring_mtime_cache
    mtime = @index.mtime(@root)
    touch "baz.txt"
    @index.expire_mtimes
    assert mtime < @index.mtime(@root)
    assert @index.files(@root).include?("baz.txt")
  end

  def test_expiring_file_cache
    mtime = @index.mtime(@root)
    touch "baz.txt"
    @index.expire_files
    assert_equal mtime, @index.mtime(@root)
    assert @index.files(@root).include?("baz.txt")
  end
end
