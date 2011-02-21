require "hike_test"
require "fileutils"

class DirectoryIndexTest < Test::Unit::TestCase
  include FileUtils

  def setup
    @root = File.join(FIXTURE_ROOT, "tmp")
    @index = Hike::DirectoryIndex.new

    mkdir_p @root
    mkdir_p fixture_path("baz")
    touch fixture_path("foo.txt")
    touch fixture_path("bar.txt")
  end

  def teardown
    rm_rf @root
  end

  def fixture_path(path)
    File.join(@root, path)
  end

  def test_entries
    assert_equal ["bar.txt", "baz", "foo.txt"], @index.entries(@root).map(&:to_s)
    assert_equal [], @index.entries(fixture_path("baz"))
  end

  def test_files
    assert_equal ["bar.txt", "foo.txt"], @index.files(@root)
    assert_equal [], @index.files(fixture_path("foo.txt"))
    assert_equal [], @index.files(fixture_path("nonexistent"))
  end

  def test_files_are_cached
    files = @index.files(@root)
    touch fixture_path("baz.txt")
    assert_equal files, @index.files(@root)
  end

  def test_expire_cache
    assert !@index.files(@root).include?("baz.txt")
    touch fixture_path("baz.txt")
    assert !@index.files(@root).include?("baz.txt")
    @index.expire_cache
    assert @index.files(@root).include?("baz.txt")
  end
end
