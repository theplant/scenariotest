class Store < ActiveRecord::Base
  belongs_to :city
  has_many :drinks, :class_name => "Cafe::Drink"

  class << self
    attr_accessor :biggest
  end

end
