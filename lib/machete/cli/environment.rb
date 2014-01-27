##
# Class Machete::CLI::Cookbook
#
require "machete/control/environment"

module Machete
  module CLI
    class Environment < Thor

      attr_reader :controller
      def initialize(*args)
        super(*args)
        @controller = Machete::Control::Environment.new(Machete.model)
      end

      #      desc "list", "List configured cookbooks"
      #      def list
      #        say "cookbooks"
      #      end

      desc "create", "Save current cookbook versions in a new environent"
      option :description, :type => :string, :default => "", :aliases => :m
      def create(type=:patch, pre=:alpha)
        @controller.create(type, pre, options.symbolize_keys)
        
        puts Machete.model.to_json
      end

#      desc "upload", "Upload cookbooks from the berkshelf to Chef servers"
#      option :force, :type => :boolean, :default => false, :aliases => :f
#      option :clusters, :type => :string, :default => [], :aliases => :c
#      option :no_freeze, :type => :boolean, :default => false
#      option :halt_on_frozen, :type => :boolean, :default => false
#      option :ignore_dependencies, :type => :boolean, :default => false, :aliases => :i
#
#      def upload(*cookbooks)
#        options[:cookbooks] = cookbooks
#        options[:freeze] = !options[:no_freeze]
#        @controller.upload(options.symbolize_keys)
#      end
#
#      desc "delete", "Remove cookbooks from Chef servers"
#      option :clusters, :type => :string, :default => [], :aliases => :c
#      option :purge, :type => :boolean, :default => false
#
#      def delete(cookbook, version=nil)
#        @controller.delete(cookbook, version, options.symbolize_keys)
#      end
    end
  end
end
