require "cleaver/model/entity"

module Cleaver
  module Model
    ##
    # Node Type Descriptor
    ##
    class Type < Cleaver::Model::Entity
      class << self
        def type(name, &block)
          entity = Type.new(name)
          entity.instance_exec(&block) if block

          Type[name] = entity.complete
        end

        def load(name)
          collection[name] = Type.new(name).load
        end

        def load_all
          Dir.glob(storage_path.join("*.json")).each { |file| load(File.basename(file, ".json")) }

          collection
        end

        def exist?(name)
          File.exist?(storage_path.join("#{ name }.json"))
        end

        def storage_path
          Cleaver.store.join("types")
        end

        def initialize_filesystem
          FileUtils.mkdir_p(storage_path, :mode => 0755)

          unless File.writable?(storage_path)
            fail Cleaver::Error, "You do not have permission to write to '#{storage_path}'! " <<
            "Please either chown the directory or use a different location."
          end
        end
      end

      ##
      # Cleaverfile DSL for Type
      ##
      module DSL
        def type(*args, &block)
          Type.type(*args, &block)
        end
      end

      attribute :name
      attribute :description
      attribute :run_list
      attr_reader :serial

      export :name, :description, :run_list, :serial

      def initialize(name, options = {})
        @name = name
        @description = options[:description] || "#{ name } Nodes"
        @run_list = options[:run_list] || []
      end

      def inc_serial
        @serial += 1
      rescue NoMethodError
        @serial = 0
      end

      def file_path
        Type.storage_path.join("#{ name }.json")
      end

      def load
        source = JSON.parse(IO.read(file_path), :symbolize_names => true) rescue {}
        @description ||= source[:description]
        @run_list ||= source[:run_list]
        @serial = source[:serial]

        self
      end
      alias_method :complete, :load

      def save
        IO.write(file_path, to_json)
      end
    end
  end
end
