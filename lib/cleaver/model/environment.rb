##
# Class: Cleaver::Model::Environment
#
require "fileutils"
require "json"
require "pathname"

module Cleaver
  module Model
    class Environment < Cleaver::Model::Entity
      class << self
        def load(name)
          source = IO.read(storage_path.join("#{ name }.json"))
          Environment.new(name, JSON.parse(source, :symbolize_names => true))
        end

        def load_all
          Hash[Dir.glob(storage_path.join("*.json")).map { |file|
            name = File.basename(file, ".json")

            [ name, load(name) ]
          }]
        end

        def exist?(name)
          File.exist?(storage_path.join("#{ name }.json"))
        end

        def storage_path
          Cleaver.store.join("environments")
        end

        def initialize_filesystem
          FileUtils.mkdir_p(storage_path, :mode => 0755)

          unless File.writable?(storage_path)
            raise InsufficientPrivledges, "You do not have permission to write to '#{storage_path}'! " <<
            "Please either chown the directory or use a different location."
          end
        end
      end

      attribute :name
      attribute :description
      attribute :cookbooks

      export :name, :description, :cookbooks

      def initialize(name, options={})
        @name = name
        @description = options[:description] || "Version #{ name }"
        @cookbooks = options[:cookbooks] || {}
      end

      def ==(compare)
        return false unless(compare.is_a?(Environment))
        cookbooks == compare.cookbooks
      end

      def file_path
        Environment.storage_path.join("#{ name }.json")
      end

      def relative_path
        File.join(".cleaver/environments", "#{ name }.json")
      end

      def cookbook_shelf
        shelf = Cleaver::Model::Cookbook::Shelf.new
        cookbooks.each do |name, cookbook|
          cookbook = cookbook.dup

          ## Fix attributes
          cookbook[:constraint] = "= #{cookbook.delete(:version)}"
          cookbook.delete(:name)

          shelf.cookbook(name, nil, cookbook)
        end

        shelf
      end

      def chef_hash
        {
          :name => name.gsub(".", "_"),
          :description => description,
          :cookbook_versions => Hash[@cookbooks.map {|c| [c[0], "= #{c[1][:version]}"] }]
        }
      end

      def save
        IO.write(file_path, to_json)
      end
    end
  end
end
