##
# Class Machete::CLI::Cookbook
#
require "machete/control/environment"

module Machete
  module CLI
    class Environment < Machete::CLI::Base
      def list
        puts " --- Environments ---"
        Machete::Model::Environment.load_all.each do |name, env|
          printf " * %s  -  %s\n", name, env.description
        end
        puts ""
      end

      flag :force, :alias => :f
      option :description, :kind_of => String, :alias => :m
      option :prerelease_type, :kind_of => String, :default => "alpha", :alias => :p

      def create(type=:patch)
        Machete::Control::Environment.create(type, options)
      end
    end
  end
end
