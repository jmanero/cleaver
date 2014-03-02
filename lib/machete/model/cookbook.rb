##
# Class: Machete::Model::Cookbooks
#
require "berkshelf"
require "fileutils"
require "pathname"

module Machete
  class Model
    class Cookbook < Berkshelf::CookbookSource
      module IShelf
        extend Machete::Model::Helpers
        def cookbook(name, constraint=nil, options={})
          if(constraint.is_a?(Hash))
            options = constraint
            constraint = nil
          end

          options[:path] &&= Machete::Config.relative(options[:path])
          options[:constraint] = constraint unless(constraint.nil?)

          collection[name] = Cookbook.new(self, name.to_s, options)
        end

        dispatch :filepath, Machete::Config, :file_path

        def sources
          collection.values
        end

        ## Getters
        def collection
          @collection ||= Machete::Model::Collection.new
        end
      end

      class Shelf
        include IShelf
        
        def cache
          Cookbook.cache
        end
        def downloader
          Cookbook.downloader
        end
        def store
          Cookbook.store
        end
        def current
          Cookbook.current
        end
      end

      class << self
        include IShelf
        def cache
          @cache ||= []
        end

        def downloader
          @downloader ||= Berkshelf::Downloader.new(store)
        end

        def store
          @store ||= Berkshelf::CookbookStore.new(storage_path)
        end

        def current
          Hash[cache.map do |c|
            _name = c.cookbook_name.to_sym;
            _params = { :version => c.version }

            ## Get parameters from configuration
            _params.merge!(collection[_name].to_hash) if(collection.include?(_name))

            [_name, _params]
          end]
        end

        def file_path
          Machete::Config.store.to_s
        end

        def storage_path
          Machete::Config.store.join("cookbooks")
        end

        def initialize_filesystem
          FileUtils.mkdir_p(storage_path, :mode => 0755)

          unless File.writable?(storage_path)
            raise InsufficientPrivledges, "You do not have permission to write to '#{storage_path}'! " <<
            "Please either chown the directory or use a different location."
          end
        end
      end

      module DSL
        def site(uri)
          Machete::Model::Cookbook.downloader.add_location(:site, uri)
        end

        def chef_api(value, options = {})
          Cookbook.downloader.add_location(:chef_api, value, options={})
        end

        def cookbook(*args)
          Cookbook.cookbook(*args)
        end
      end

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
  end
end
