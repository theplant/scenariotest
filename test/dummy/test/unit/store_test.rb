require 'test_helper'

class StoreTest < ActiveSupport::TestCase
  setup do
    S.setup(:cafes)
  end

  test "store have city" do
    assert S[:starbucks].city
    assert S[:metoo].city
  end

  test "transient variable set" do
    assert Store.biggest
  end

end
