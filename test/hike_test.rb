require "minitest/autorun"
require "hike"

FIXTURE_ROOT = File.expand_path(File.join(File.dirname(__FILE__), "fixtures"))

module Hike
  if defined? Minitest::Test
    klass = Minitest::Test
  elsif defined? MiniTest::Unit::TestCase
    klass = MiniTest::Unit::TestCase
  end

  class Test < klass
  end
end
