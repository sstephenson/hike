require "hike_test"

class TrailTest < Test::Unit::TestCase
  attr_reader :trail

  def setup
    @trail = Hike::Trail.new(FIXTURE_ROOT)
    @trail.paths.push "app/views", "vendor/plugins/signal_id/app/views", "."
    @trail.extensions.push "builder", ".erb"
  end

  def fixture_path(path)
    File.expand_path(File.join(FIXTURE_ROOT, path))
  end

  def test_find_nonexistent_file
    assert_nil trail.find("people/show.html")
  end

  def test_find_without_an_extension
    assert_equal(
      fixture_path("app/views/projects/index.html.erb"),
      trail.find("projects/index.html")
    )
  end

  def test_find_with_an_extension
    assert_equal(
      fixture_path("app/views/projects/index.html.erb"),
      trail.find("projects/index.html.erb")
    )
  end

  def test_find_respects_path_order
    assert_equal(
      fixture_path("app/views/layouts/interstitial.html.erb"),
      trail.find("layouts/interstitial.html")
    )

    trail.paths.replace trail.paths.reverse

    assert_equal(
      fixture_path("vendor/plugins/signal_id/app/views/layouts/interstitial.html.erb"),
      trail.find("layouts/interstitial.html")
    )
  end

  def test_find_respects_extension_order
    assert_equal(
      fixture_path("app/views/recordings/index.atom.builder"),
      trail.find("recordings/index.atom")
    )

    trail.extensions.replace trail.extensions.reverse

    assert_equal(
      fixture_path("app/views/recordings/index.atom.erb"),
      trail.find("recordings/index.atom")
    )
  end

  def test_find_with_multiple_logical_paths_returns_first_match
    assert_equal(
      fixture_path("app/views/recordings/index.html.erb"),
      trail.find("recordings/index.txt", "recordings/index.html", "recordings/index.atom")
    )
  end

  def test_find_file_in_path_root_returns_expanded_path
    assert_equal(
      fixture_path("app/views/index.html.erb"),
      trail.find("index.html")
    )
  end

  def test_find_extensionless_file
    assert_equal(
      fixture_path("README"),
      trail.find("README")
    )
  end
end
