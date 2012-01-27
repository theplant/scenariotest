require 'test_helper'

class Cafe::DrinkTest < ActiveSupport::TestCase
  setup do
    S.setup(:cafes, :drinks)
  end

  test "have both cafes and drinks" do
    assert S[:starbucks]
    assert S[:latte]
  end

  test "has many drinks" do
    S.setup(:starbucks_with_drinks)
    assert_equal(2, S[:starbucks].drinks.size, S[:starbucks].drinks.count)
    assert_equal(2, Store.count, Store.count)
  end

end
