class Store < ActiveRecord::Base
  belongs_to :city
  has_many :drinks, :class_name => "Cafe::Drink"

  class << self
    attr_reader :biggest
    attr_accessor :biggest_set_count

    def biggest=(big)
      @biggest_set_count ||= 0
      @biggest_set_count = @biggest_set_count + 1
      @biggest = big
    end
  end

end
