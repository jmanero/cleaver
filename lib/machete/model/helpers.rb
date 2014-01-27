##
# Class: Machete::Config::DSL
#
require "json"

module Machete
  class Model
    module Helpers
      ## Define getters and setters for an attribute.
      # TODO Add validation handling like Chef LWRPs
      def attribute(name, validation={})
        ivar = "@#{name}"

        ## Getter/setter
        define_method(name) do |*args|
          instance_variable_set(ivar, args.first) if(args.first)
          instance_variable_get(ivar)
        end

        ## = Setter
        define_method("#{name}=") do |arg|
          instance_variable_set(ivar, arg); arg
        end
      end

      ## Create an alias to a receiver in another instance
      def dispatch(name, delegate, ualias=nil, &cblock)
        receiver = (ualias || name).to_sym

        if(delegate.is_a?(Module))
          ## Module/Class dispatch
          define_method(name.to_sym) do |*args, &block|
            dres = delegate.send(receiver, *args, &block)
            instance_exec(dres, &cblock) if(cblock)
          end
        else
          ## Instance dispatch
          define_method(name.to_sym) do |*args, &block|
            ivar = respond_to?(delegate) ? send(delegate) : instance_variable_get("@#{delegate}")
            dres = ivar.send(receiver, *args, &block)
            instance_exec(dres, &cblock) if(cblock)
          end
        end
      end

      def export(*attrs, &block)
        define_method(:to_hash) do
          hash = Hash[attrs.flatten.map {|name|
            value = respond_to?(name) ? send(name) : instance_variable_get("@#{name}")
            value =
            case value
              when Array
                value.map {|v| v.to_hash rescue v}
              when Hash
                Hash[value.map {|v| [v[0], (v[1].to_hash rescue v[1])]}]
              else
                value.to_hash rescue value
            end

            [name, value]
          }]

          ## Mixin attributes at call-time
          hash.merge!(instance_exec(&block)) if(block)
          hash
        end
      end
    end

    class Entity
      extend Machete::Model::Helpers
      class << self
        def create(*args, &block)
          entity = self.new(*args)
          entity.instance_exec(&block) if(block)
          entity.complete
        end
      end
      
      def complete
        self
      end

      def to_hash
        {}
      end

      def to_json
        JSON.pretty_generate(to_hash)
      end
    end

    class Collection
      extend Machete::Model::Helpers
      attr_reader :entities
      def initialize(model)
        @model = model
        @entities = {}
      end

      def each(&block)
        @entities.each{|k,v| block.call(k, v)}
      end
      
      def [](name)
        @entities[name]
      end
      
      def []=(name, value)
        @entities[name] = value
      end
      
      def delete(name)
        @entities.delete(name)
      end

      def to_hash
        Hash[@entities.map{|c| [c[0], c[1].to_hash] }]
      end
    end
  end
end