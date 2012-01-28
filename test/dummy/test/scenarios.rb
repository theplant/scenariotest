S.define :dalian do
  S[:dalian] = City.create!(:name => "Dalian")
end

S.after :dalian do
  City.dalian = S[:dalian]
end

S.define :cafes, :req => :dalian do
  S[:starbucks] = Store.create!(:name => "Starbucks", :city => S[:dalian])
  S[:metoo] = Store.create!(:name => "Metoo", :city => S[:dalian])
end

S.after :cafes do
  Store.biggest = S[:starbucks]
end

S.define :drinks do
  S[:orange_juice] = Cafe::Drink.create!(:name => "Orange Juice", :color => 1)
  S[:latte] = Cafe::Drink.create!(:name => "Latte", :color => 9)
end

S.define :starbucks_with_drinks, :req => [:cafes, :drinks] do
  S[:starbucks].drinks << S[:orange_juice]
  S[:starbucks].drinks << S[:latte]
end

S.define :all, :req => [:drinks, :cafes, :starbucks_with_drinks] do
end


S.define(:a) {}
S.define(:b, :req => [:a]) {}
S.define(:c, :req => [:b, :a]) {}
S.define(:d, :req => [:a]) {}
S.define(:e, :req => [:d, :c]) {}
S.define(:f, :req => [:d]) {}

