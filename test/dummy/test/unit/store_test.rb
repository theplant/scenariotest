require 'test_helper'

class StoreTest < ActiveSupport::TestCase
  setup do
    S.setup(:cafes)
  end

  test "store have city" do
    assert S[:starbucks].city
    assert S[:metoo].city
  end

end
