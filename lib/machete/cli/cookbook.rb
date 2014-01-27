##
# Class Machete::CLI::Cookbook
#
require "machete/control/cookbook"

module Machete
  module CLI
    class Cookbook < Thor
      
      attr_reader :controller
      def initialize(*args)
        super(*args)
        @controller = Machete::Control::Cookbook.new(Machete.model)
      end
      
#      desc "list", "List configured cookbooks"
#      def list
#        say "cookbooks"
#      end
      
      desc "install", "Store cookbooks in the local berkshelf"
      def install
        @controller.install
      end
      
      desc "upload", "Upload cookbooks from the berkshelf to Chef servers"
      option :force, :type => :boolean, :default => false, :aliases => :f
      option :clusters, :type => :string, :default => [], :aliases => :c
      option :no_freeze, :type => :boolean, :default => false
      option :halt_on_frozen, :type => :boolean, :default => false
      option :ignore_dependencies, :type => :boolean, :default => false, :aliases => :i
      def upload(*cookbooks)
        options[:cookbooks] = cookbooks
        options[:freeze] = !options[:no_freeze]
        @controller.upload(options.symbolize_keys)
      end
      
      desc "delete", "Remove cookbooks from Chef servers"
      option :clusters, :type => :string, :default => [], :aliases => :c
      option :purge, :type => :boolean, :default => false
      def delete(cookbook, version=nil)
        @controller.delete(cookbook, version, options.symbolize_keys)
      end
    end
  end
end
