require 'test_helper'

class Cafe::DrinkTest < ActiveSupport::TestCase
  setup do
    S.setup(:cafes, :drinks)
  end

  test "have both cafes and drinks" do
    assert S[:starbucks]
    assert S[:latte]
  end

end
