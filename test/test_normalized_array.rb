require "hike_test"

class UppercaseArray < Hike::NormalizedArray
  def normalize_element(element)
    element.upcase
  end
end

class NormalizedArrayTest < Test::Unit::TestCase
  def setup
    @array = UppercaseArray.new
  end

  def test_brackets_with_start_and_length
    @array.push "a", "b", "c"
    @array[0, 2] = ["d"]
    assert_equal ["D", "C"], @array
  end

  def test_brackets_with_range
    @array.push "a", "b", "c"
    @array[0..1] = ["d"]
    assert_equal ["D", "C"], @array
  end

  def test_brackets_with_index
    @array.push "a", "b", "c"
    @array[0] = "d"
    assert_equal ["D", "B", "C"], @array
  end

  def test_arrows
    @array << "a"
    assert_equal ["A"], @array
  end

  def test_collect_bang
    @array.push "aa", "bb", "cc"
    @array.collect! { |i| i[/^./].downcase }
    assert_equal ["A", "B", "C"], @array
  end

  def test_map_bang
    @array.push "aa", "bb", "cc"
    @array.map! { |i| i[/^./].downcase }
    assert_equal ["A", "B", "C"], @array
  end

  def test_insert
    @array.push "a", "b", "c"
    @array.insert 0, "d", "e"
    assert_equal ["D", "E", "A", "B", "C"], @array
  end

  def test_push
    @array.push "a", "b", "c"
    assert_equal ["A", "B", "C"], @array
  end

  def test_replace
    @array.replace ["a"]
    assert_equal ["A"], @array
  end

  def test_unshift
    @array.push "a"
    @array.unshift "b", "c"
    assert_equal ["B", "C", "A"], @array
  end
end
