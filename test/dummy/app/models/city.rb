class City < ActiveRecord::Base
  class << self
    attr_accessor :dalian
  end
end
