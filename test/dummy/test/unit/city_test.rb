require 'test_helper'

class CityTest < ActiveSupport::TestCase
  setup do
    Store.biggest_set_count = 0
    S.setup :all
  end

  test "call dependency once" do
    assert_equal(1, Store.biggest_set_count)
  end

  test "dependency list" do
    assert_equal([:a, :b, :c, :d], S.definations[:e].uniq_dependencies.map{|d| d.name})
    assert_equal([:a, :d], S.definations[:f].uniq_dependencies.map{|d| d.name})
  end

end
