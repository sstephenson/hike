require "hike_test"

class TrailTest < Test::Unit::TestCase
  attr_reader :trail

  def setup
    @trail = Hike::Trail.new(FIXTURE_ROOT)
    @trail.paths.push "app/views", "vendor/plugins/signal_id/app/views", "."
    @trail.extensions.push "builder", "coffee", "str", ".erb"
  end

  def fixture_path(path)
    File.expand_path(File.join(FIXTURE_ROOT, path))
  end

  def test_root_defaults_to_cwd
    Dir.chdir(FIXTURE_ROOT) do
      trail = Hike::Trail.new
      assert_equal FIXTURE_ROOT, trail.root
    end
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

  def test_find_file_with_multiple_extensions
    assert_equal(
      fixture_path("app/views/projects/project.js.coffee.erb"),
      trail.find("projects/project.js")
    )
  end

  def test_find_file_with_multiple_extensions_respects_extension_order
    assert_equal(
      fixture_path("app/views/application.js.coffee.str"),
      trail.find("application.js")
    )

    trail.extensions.replace trail.extensions.reverse

    assert_equal(
      fixture_path("app/views/application.js.coffee.erb"),
      trail.find("application.js")
    )
  end

  def test_find_with_base_path_option_and_relative_logical_path
    assert_equal(
      fixture_path("app/views/projects/index.html.erb"),
      trail.find("./index.html", :base_path => fixture_path("app/views/projects"))
    )
  end

  def test_find_ignores_base_path_option_when_logical_path_is_not_relative
    assert_equal(
      fixture_path("app/views/index.html.erb"),
      trail.find("index.html", :base_path => fixture_path("app/views/projects"))
    )
  end

  def test_base_path_option_must_be_expanded
    assert_nil trail.find("./index.html", :base_path => "app/views/projects")
  end

  def test_relative_files_must_exist_in_the_path
    assert File.exist?(File.join(FIXTURE_ROOT, "../hike_test.rb"))
    assert_nil trail.find("../hike_test.rb", :base_path => FIXTURE_ROOT)
  end

  def test_find_all_respects_path_order
    results = []
    trail.find("layouts/interstitial.html") do |path|
      results << path
    end
    assert_equal [
      fixture_path("app/views/layouts/interstitial.html.erb"),
      fixture_path("vendor/plugins/signal_id/app/views/layouts/interstitial.html.erb")
    ], results
  end

  def test_find_all_with_multiple_extensions_respects_extension_order
    results = []
    trail.find("application.js") do |path|
      results << path
    end
    assert_equal [
      fixture_path("app/views/application.js.coffee.str"),
      fixture_path("app/views/application.js.coffee.erb")
    ], results
  end
end
