require "hike_test"
require "pathname"

class FileUtilsTest < Hike::Test
  def test_stat
    assert_kind_of File::Stat, Hike::FileUtils.stat(FIXTURE_ROOT)
    refute Hike::FileUtils.stat("/tmp/hike/missingfile")
  end

  def test_entires
    expected = [
      "application.js.coffee.erb",
      "application.js.coffee.str",
      "index.html.erb",
      "index.php",
      "layouts",
      "people.coffee",
      "people.htm",
      "projects",
      "projects.erb",
      "recordings",
    ]
    assert_equal expected, Hike::FileUtils.entries(File.join(FIXTURE_ROOT, "app/views"))

    assert_equal [], Hike::FileUtils.entries("/tmp/hike/missingdirectory")
  end
end
