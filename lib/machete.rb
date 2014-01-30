##
# Class: Machete
#
require "machete/model"

module Machete
  class MacheteError < StandardError
    ## Don't print traces for these
  end

  class << self
    def model
      @model ||= Machete::Model.new
    end
  end
end
