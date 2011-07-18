require "hike_test"
require "fileutils"

module TrailTests
  def fixture_path(path)
    File.expand_path(File.join(FIXTURE_ROOT, path))
  end

  def test_root
    assert_equal FIXTURE_ROOT, trail.root
  end

  def test_paths
    assert_equal [
      fixture_path("app/views"),
      fixture_path("vendor/plugins/signal_id/app/views"),
      fixture_path(".")
    ], trail.paths
  end

  def test_extensions
    assert_equal [".builder", ".coffee", ".str", ".erb"], trail.extensions
  end

  def test_index
    assert_kind_of Hike::Index, trail.index
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

  def test_find_with_leading_slash
    assert_equal(
      fixture_path("app/views/projects/index.html.erb"),
      trail.find("/projects/index.html")
    )
  end

  def test_find_respects_path_order
    assert_equal(
      fixture_path("app/views/layouts/interstitial.html.erb"),
      trail.find("layouts/interstitial.html")
    )

    trail = new_trail { |t| t.paths.replace t.paths.reverse }

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

    trail = new_trail { |t| t.extensions.replace t.extensions.reverse }

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

    trail = new_trail { |t| t.extensions.replace t.extensions.reverse }

    assert_equal(
      fixture_path("app/views/application.js.coffee.erb"),
      trail.find("application.js")
    )
  end

  def test_find_file_by_aliased_extension
    assert_equal(
      fixture_path("app/views/people.coffee"),
      trail.find("people.coffee")
    )

    assert_equal(
      fixture_path("app/views/people.coffee"),
      trail.find("people.js")
    )

    assert_equal(
      fixture_path("app/views/people.htm"),
      trail.find("people.htm")
    )

    assert_equal(
      fixture_path("app/views/people.htm"),
      trail.find("people.html")
    )
  end

  def test_find_file_with_aliases_prefers_primary_extension
    assert_equal(
      fixture_path("app/views/index.html.erb"),
      trail.find("index.html")
    )
    assert_equal(
      fixture_path("app/views/index.php"),
      trail.find("index.php")
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

  def test_find_filename_instead_directory
    assert_equal(
      fixture_path("app/views/projects.erb"),
      trail.find("projects")
    )
  end

  def test_ignores_directories
    assert_nil trail.find("recordings")
  end

  def test_entries
    expected = [
      Pathname.new("application.js.coffee.erb"),
      Pathname.new("application.js.coffee.str"),
      Pathname.new("index.html.erb"),
      Pathname.new("index.php"),
      Pathname.new("layouts"),
      Pathname.new("people.coffee"),
      Pathname.new("people.htm"),
      Pathname.new("projects"),
      Pathname.new("projects.erb"),
      Pathname.new("recordings"),
    ]
    assert_equal expected, trail.entries(fixture_path("app/views")).sort
  end

  def test_stat
    assert trail.stat(fixture_path("app/views/index.html.erb"))
    assert trail.stat(fixture_path("app/views"))
    assert_nil trail.stat(fixture_path("app/views/missing.html"))
  end
end

class TrailTest < Test::Unit::TestCase
  attr_reader :trail

  def new_trail
    trail = Hike::Trail.new(FIXTURE_ROOT)
    trail.append_path "app/views", "vendor/plugins/signal_id/app/views", "."
    trail.append_extension "builder", "coffee", "str", ".erb"
    trail.alias_extension "htm", "html"
    trail.alias_extension "xhtml", "html"
    trail.alias_extension "php", "html"
    trail.alias_extension "coffee", "js"
    yield trail if block_given?
    trail
  end

  def setup
    @trail = new_trail
  end

  def test_root_defaults_to_cwd
    Dir.chdir(FIXTURE_ROOT) do
      trail = Hike::Trail.new
      assert_equal FIXTURE_ROOT, trail.root
    end
  end

  def test_find_reflects_changes_in_the_file_system
    assert_nil trail.find("dashboard.html")
    FileUtils.touch fixture_path("dashboard.html")
    assert_equal fixture_path("dashboard.html"), trail.find("dashboard.html")
  ensure
    FileUtils.rm fixture_path("dashboard.html")
    assert !File.exist?(fixture_path("dashboard.html"))
  end

  include TrailTests
end

class IndexTest < Test::Unit::TestCase
  attr_reader :trail

  def new_trail
    trail = Hike::Trail.new(FIXTURE_ROOT)
    trail.append_path "app/views", "vendor/plugins/signal_id/app/views", "."
    trail.append_extension "builder", "coffee", "str", ".erb"
    trail.alias_extension "htm", "html"
    trail.alias_extension "xhtml", "html"
    trail.alias_extension "php", "html"
    trail.alias_extension "coffee", "js"
    yield trail if block_given?
    trail.index
  end

  def setup
    @trail = new_trail
  end

  include TrailTests

  def test_changing_trail_path_doesnt_affect_index
    trail = Hike::Trail.new(FIXTURE_ROOT)
    trail.paths.push "."

    index = trail.index

    assert_equal [fixture_path(".")], trail.paths
    assert_equal [fixture_path(".")], index.paths

    trail.paths.push "app/views"

    assert_equal [fixture_path("."), fixture_path("app/views")], trail.paths
    assert_equal [fixture_path(".")], index.paths
  end

  def test_changing_trail_extensions_doesnt_affect_index
    trail = Hike::Trail.new(FIXTURE_ROOT)
    trail.extensions.push "builder"

    index = trail.index

    assert_equal [".builder"], trail.extensions
    assert_equal [".builder"], index.extensions

    trail.extensions.push "str"

    assert_equal [".builder", ".str"], trail.extensions
    assert_equal [".builder"], index.extensions
  end

  def test_find_does_not_reflect_changes_in_the_file_system
    assert_nil trail.find("dashboard.html")
    FileUtils.touch fixture_path("dashboard.html")
    assert_nil trail.find("dashboard.html")
  ensure
    FileUtils.rm fixture_path("dashboard.html")
    assert !File.exist?(fixture_path("dashboard.html"))
  end
end
