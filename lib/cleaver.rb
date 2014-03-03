##
# Class: Cleaver
#
require "pathname"
require "cleaver/cli"

module Cleaver
  class CleaverError < StandardError
    ## Don't print traces for these
  end

  class << self
    def directory
      @directory ||= Pathname.new(Dir.pwd)
    end

    def file
      directory.join("Cleaverfile")
    end

    def store
      directory.join(".cleaver")
    end
  end
end
