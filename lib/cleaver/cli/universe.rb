##
# Class Cleaver::CLI::Universe
#
require "cleaver/control/universe"

module Cleaver
  module CLI
    class Universe < Cleaver::CLI::Base
      def initialize(argv, _options)
        @universe = argv.shift.to_sym
        Cleaver::Log.info("Using universe #{ @universe }")

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
      #        Cleaver::Control::Universe.apply(environment, options)
      #      end

      def upload(version=nil, *cookbooks)
        options[:cookbooks] = cookbooks
        options[:freeze] = !options[:no_freeze]
        Cleaver::Control::Universe.upload(@universe, version, options)
      end

      def delete(cookbook, version=nil)
        Cleaver::Control::Universe.delete(@universe, cookbook, version, options)
      end

      def delete_all
        Cleaver::Control::Universe.delete_all(@universe, options)
      end
    end
  end
end
