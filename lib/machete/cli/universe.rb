##
# Class Machete::CLI::Universe
#
require "machete/control/universe"

module Machete
  module CLI
    class Universe < Machete::CLI::Base

      attr_reader :controller
      def initialize(*args)
        super(*args)
        @controller = Machete::Control::Universe.new(options[:universe], Machete.model)
      end

      def arguments(universe)
        options[:universe] = universe.to_sym
        Machete::Log.debug("Using universe #{universe}")
      end

      flag :force, :alias => :f
      flag :no_freeze
      flag :halt_on_frozen
      flag :ignore_dependencies, :alias => :i
      flag :purge, :alias => :p
      option :cluster, :kind_of => String, :multi => true, :alias => :c

      def noop
        puts "Universe #{options}"
      end

      def upload(environment=nil, *cookbooks)
        options[:cookbooks] = cookbooks
        options[:freeze] = !options[:no_freeze]
        @controller.upload(environment, options)
      end

      def delete(cookbook, version=nil)
        @controller.delete(cookbook, version, options)
      end
      
      def delete_all
        @controller.delete_all(options)
      end
    end
  end
end
