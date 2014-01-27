##
# Class: Machete::Model::Environment
#
require "fileutils"
require "json"
require "pathname"

module Machete
  class Model
    class Environment < Machete::Model::Entity
      attribute :name
      attribute :description
      def initialize(collection, name, options={})
        @collection = collection
        @name = name

        @description = options[:description] || options["description"] || ""
        @versions = options[:versions] || options["versions"] || {}
      end

      export :name, :description, :versions

      def save
        IO.write(@collection.storage_path.join("#{ name }.json"), to_json)
      end
    end

    class Environments < Machete::Model::Collection
      attr_reader :storage_path
      def initialize(*args)
        @storage_path = Machete::Config.store.join("environments")
        initialize_filesystem
        super(*args)
      end

      def environment(name, versions={})
        @entities[name] = Environment.new(self, name, versions)
      end

      def load_files
        Dir.glob(storage_path.join("*.json")) do |file|
          name = File.basename(file, ".json")
          source = IO.read(storage_path.join(file))
          @entities[name] = Environment.new(self, name, JSON.parse(source))
        end
        
        self
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
