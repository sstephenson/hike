require "test_helper"

class TestTrail < Hike::Trail
  def initialize(files)
    super "/test"
    @files = files.map { |filename| File.join(root, filename) }
  end

  protected
    def exists?(path)
      @files.include?(path)
    end
end

class TrailTest < Test::Unit::TestCase
  attr_reader :trail

  def setup
    @trail = TestTrail.new [
      "app/views/layouts/interstitial.html.erb",
      "app/views/projects/index.html.erb",
      "app/views/recordings/index.atom.builder",
      "app/views/recordings/index.atom.erb",
      "vendor/plugins/signal_id/app/views/layouts/interstitial.html.erb"
    ]

    @trail.paths.push "app/views", "/test/vendor/plugins/signal_id/app/views"
    @trail.extensions.push "builder", ".erb"
  end

  def test_find_nonexistent_file
    assert_nil trail.find("people/show.html")
  end

  def test_find_without_an_extension
    assert_equal "/test/app/views/projects/index.html.erb",
      trail.find("projects/index.html")
  end

  def test_find_with_an_extension
    assert_equal "/test/app/views/projects/index.html.erb",
      trail.find("projects/index.html.erb")
  end

  def test_find_respects_path_order
    assert_equal "/test/app/views/layouts/interstitial.html.erb",
      trail.find("layouts/interstitial.html")

    trail.paths.replace trail.paths.reverse

    assert_equal "/test/vendor/plugins/signal_id/app/views/layouts/interstitial.html.erb",
      trail.find("layouts/interstitial.html")
  end

  def test_find_respects_extension_order
    assert_equal "/test/app/views/recordings/index.atom.builder",
      trail.find("recordings/index.atom")

    trail.extensions.replace trail.extensions.reverse
    
    assert_equal "/test/app/views/recordings/index.atom.erb",
      trail.find("recordings/index.atom")
  end
end
