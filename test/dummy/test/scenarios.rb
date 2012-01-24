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

