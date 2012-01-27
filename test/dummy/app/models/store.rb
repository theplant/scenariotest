class Store < ActiveRecord::Base
  belongs_to :city
  has_many :drinks, :class_name => "Cafe::Drink"
end
