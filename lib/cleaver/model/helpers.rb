##
# Class: Cleaver::Model::Helpers
#
require "json"

module Cleaver
  module Model
    ##
    # Model Helpers
    ##
    module Helpers
      ## Define getters and setters for an attribute.
      # TODO: Add validation handling like Chef LWRPs
      def attribute(name, validation = {})
        ivar = "@#{name}"

        ## Getter/setter
        define_method(name) do |*args|
          instance_variable_set(ivar, args.first) if args.first
          instance_variable_get(ivar)
        end

        ## = Setter
        define_method("#{name}=") do |value|
          instance_variable_set(ivar, value)
          value
        end
      end

      ## Create an alias to a receiver in another instance
      def dispatch(name, delegate, ualias = nil, &cblock)
        receiver = (ualias || name).to_sym
        target = if delegate.is_a?(Module)
          delegate ## Module/Class dispatch
        else
          ## Instance variable/method dispatch
          respond_to?(delegate) ? send(delegate) : instance_variable_get("@#{delegate}")
        end

        define_method(name.to_sym) do |*args, &block|
          result = target.send(receiver, *args, &block)
          instance_exec(result, &cblock) if cblock
        end
      end

      def export(*attrs, &block)
        define_method(:to_hash) do
          hash = Hash[attrs.flatten.map do |name|
            ## Instance variable or method
            value = respond_to?(name) ? send(name) : instance_variable_get("@#{name}")

            ## Handle collections
            value = case value
              when Array
                value.map { |v| v.to_hash rescue v }
              when Hash
                Hash[value.map { |v| [v[0], (v[1].to_hash rescue v[1])] }]
              else
                value.to_hash rescue value
            end

            [name, value]
          end]

          ## Mixin attributes at call-time
          hash.merge!(instance_exec(&block)) if block
          hash
        end
      end
    end
  end
end
