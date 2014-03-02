##
# Class Machete::CLI::Universe
#
require "machete/control/universe"

module Machete
  module CLI
    class Universe < Machete::CLI::Base
      def initialize(argv, _options)
        @universe = argv.shift.to_sym
        Machete::Log.info("Using universe #{ @universe }")

        super(argv, _options)
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

      #      def apply(environment)
      #        Machete::Control::Universe.apply(environment, options)
      #      end

      def upload(version=nil, *cookbooks)
        options[:cookbooks] = cookbooks
        options[:freeze] = !options[:no_freeze]
        Machete::Control::Universe.upload(@universe, version, options)
      end

      def delete(cookbook, version=nil)
        Machete::Control::Universe.delete(@universe, cookbook, version, options)
      end

      def delete_all
        Machete::Control::Universe.delete_all(@universe, options)
      end
    end
  end
end
