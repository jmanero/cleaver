require "fileutils"
require "json"
require "pathname"
require "thor-scmversion/prerelease"
require "thor-scmversion/scm_version"
require "cleaver/model/entity"

module Cleaver
  module Model
    ##
    # Environment Entity
    ##
    class Environment < Cleaver::Model::Entity
      class << self
        def load(name)
          source = IO.read(storage_path.join("#{ name }.json"))
          collection[name] = Environment.new(name, JSON.parse(source, :symbolize_names => true))
        end

        def load_all
          Dir.glob(storage_path.join("*.json")).each { |file| load(File.basename(file, ".json")) }

          collection
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
            fail Cleaver::Error, "You do not have permission to write to '#{storage_path}'! " <<
            "Please either chown the directory or use a different location."
          end
        end
      end

      attribute :name
      attribute :description
      attribute :cookbooks

      export :name, :description, :cookbooks

      attr_reader :version

      def initialize(name, options = {})
        @name = name
        @version = ThorSCMVersion::ScmVersion.from_tag(name)
        @description = options[:description] || "Version #{ name }"
        @cookbooks = options[:cookbooks] || {}
      end

      def ==(other)
        return false unless other.is_a?(Environment)
        cookbooks == other.cookbooks
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
          :cookbook_versions => Hash[@cookbooks.map { |c| [c[0], "= #{c[1][:version]}"] }]
        }
      end

      def save
        IO.write(file_path, to_json)
      end
    end
  end
end
