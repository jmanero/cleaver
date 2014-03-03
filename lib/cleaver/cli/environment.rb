##
# Class Cleaver::CLI::Cookbook
#
require "cleaver/control/environment"

module Cleaver
  module CLI
    class Environment < Cleaver::CLI::Base
      def list
        puts " --- Environments ---"
        Cleaver::Model::Environment.load_all.each do |name, env|
          printf " * %s  -  %s\n", name, env.description
        end
        puts ""
      end

      flag :force, :alias => :f
      option :description, :kind_of => String, :alias => :m
      option :prerelease_type, :kind_of => String, :default => "alpha", :alias => :p

      def create(type=:patch)
        Cleaver::Control::Environment.create(type, options)
      end
    end
  end
end
