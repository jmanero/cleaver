##
# Class Machete::CLI::Cookbook
#
require "machete/control/environment"

module Machete
  module CLI
    class Environment < Machete::CLI::Base

      attr_reader :controller
      def initialize(*args)
        super(*args)
        @controller = Machete::Control::Environment.new(Machete.model)
      end

      def list
        puts " --- Environments ---"
        Machete.model.environments.each do |name, env|
          printf " * %s  -  %s\n", name, env.description
        end
        puts ""
      end

      flag :force, :alias => :f
      option :description, :kind_of => String, :alias => :m
      option :prerelease_type, :kind_of => String, :default => "alpha", :alias => :p

      def create(type=:patch)
        @controller.create(type, options)
      end
    end
  end
end
