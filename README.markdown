Why
=====

I think Test Case are made up with these:

1. Certain state (snapshot) of a whole database
1. Code to read or change the state of the the database
1. Assertions for the change of database state or generated http response

The current way of change the state of database are loading yaml files (Rails Fixture) or every time create objects by ActiveRecord or FactoryGirl. when you create a lots of records, it tends to be slow.

So why not use the fastest native `mysqldump` and `mysql` to load the snapshot of database for each test case.


How to use
==========
1. Create a ruby file like `scenarios.rb` under your test directory:

``` ruby
S.define :dalian do
  S[:dalian] = City.create!(:name => "Dalian")
end

S.define :cafes, :req => :dalian do
  S[:starbucks] = Store.create!(:name => "Starbucks", :city => S[:dalian])
  S[:metoo] = Store.create!(:name => "Metoo", :city => S[:dalian])
end

S.define :drinks do
  S[:orange_juice] = Cafe::Drink.create!(:name => "Orange Juice", :color => 1)
  S[:latte] = Cafe::Drink.create!(:name => "Latte", :color => 9)
end

S.define :starbucks_with_drinks, :req => [:cafes, :drinks] do
  S[:starbucks].drinks << S[:orange_juice]
  S[:starbucks].drinks << S[:latte]
end
```
Which you can define groups of objects as scenario, can depend on other scenario you defined. So that you can use in your test case setup block.


1. And in your test_helper.rb:

``` ruby
ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

S = Scenariotest::Scenario.init
require 'scenarios'
```

1. Then in your test file:

You can use the objects created for you freely

``` ruby
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
```


How it works
============

First time you call `S.setup(:starbucks_with_drinks)` it will do:

1. empty the whole database
1. invoke the blocks and create data from the blocks you defined and store the objects you created to `S[]`
1. dump the database data (not schema) to tmp/scenariotest_fixtures/
1. dump the loaded objects ids to tmp/scenariotest_fixtures/

Next time you run tests and call `S.setup(:starbucks_with_drinks)` it will do:

1. load the dump database data
1. load the objects into `S[]`




