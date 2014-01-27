##
# Class: Machete
#
require "machete/model"

module Machete
  class << self
    def model
      @model ||= Machete::Model.new
    end
  end
end
