##
# Class: Machete::Model::Cookbooks
#
require "berkshelf"
require "fileutils"
require "pathname"

module Machete
  class Model
    class Cookbook < Berkshelf::CookbookSource
      def to_hash
        {
          :name => name,
          :constraint => version_constraint.to_s,
        }.tap do |h|
          if location.kind_of?(Berkshelf::SiteLocation)
            h[:site] = location.api_uri if location.api_uri != CommunityREST::V1_API
          end

          if location.kind_of?(Berkshelf::PathLocation)
            h[:path] = location.relative_path(berksfile.filepath)
          end

          if location.kind_of?(Berkshelf::GitLocation)
            h[:git] = location.uri
            h[:ref] = location.ref
            h[:rel] = location.rel if location.rel
          end
        end
      end
    end

    class Cookbooks < Machete::Model::Collection
      attr_reader :storage_path

      ## Berkshelf::Berksfile Interface
      attr_accessor :cache
      attr_reader :downloader
      dispatch :file_path, :model
      alias_method :filepath, :file_path
      def sources
        @entities.values
      end

      def initialize(model)
        @storage_path = Machete::Config.store.join("cookbooks")
        initialize_filesystem

        @store = Berkshelf::CookbookStore.new(Machete::Config.store.join("cookbooks"))
        @downloader = Berkshelf::Downloader.new(@store)
        @cache = []
        super(model)
      end

      def current
        Hash[@cache.map do |c|
          _name = c.cookbook_name.to_sym;
          _params = { :version => c.version }

          ## Get parameters from configuration
          _params.merge!(@entities[_name].to_hash) if(include?(_name))

          [_name, _params]
        end]
      end

      ## DSL
      def site(uri)
        @downloader.add_location(:site, uri)
      end

      def chef_api(value, options = {})
        @downloader.add_location(:chef_api, value, options={})
      end

      def cookbook(name, constraint=nil, options={})
        if(constraint.is_a?(Hash))
          options = constraint
          constraint = nil
        end

        options[:path] &&= Machete::Config.relative(options[:path])
        options[:constraint] = constraint unless(constraint.nil?)
        @entities[name.to_sym] = Cookbook.new(self, name.to_s, options)
      end

      private

      def initialize_filesystem
        FileUtils.mkdir_p(storage_path, :mode => 0755)

        unless File.writable?(storage_path)
          raise InsufficientPrivledges, "You do not have permission to write to '#{storage_path}'! " <<
          "Please either chown the directory or use a different location."
        end
      end
    end
  end
end
