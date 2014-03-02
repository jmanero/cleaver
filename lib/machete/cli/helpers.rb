module Machete
  module CLI
    module Helpers
      ## Define an option: `--name value`
      def option(name, argopts={})
        _name = "option_#{name}".to_sym
        define_method(_name) do |value|
          _validate(name, value, argopts)

          if(argopts[:multi])
            options[name.to_sym] ||= []
            options[name.to_sym] << value
          else
            options[name.to_sym] = value
          end
        end

        # Option Alias
        unless(argopts[:alias].nil?)
          _alias = "option_#{argopts[:alias]}".to_sym
          alias_method _alias, _name
        end

        # Option Default
        defaults[name.to_sym] = [] if(argopts[:multi])
        defaults[name.to_sym] = argopts[:default] unless(argopts[:default].nil?)
      end

      ## Define a flag `--name`
      def flag(name, argopts={})
        _name = "flag_#{name}".to_sym
        define_method(_name) do
          options[name.to_sym] = true
        end

        # Flag Alias
        unless(argopts[:alias].nil?)
          _alias = "flag_#{argopts[:alias]}".to_sym
          alias_method _alias, _name
        end
      end

      ## Define a sub-command
      def register(klass, command, usage, desc)
        _name = "subcommand_#{command}".to_sym
        define_method(_name) do |argv|
          klass.new(argv, options).command
        end
      end
    end

    class Base
      extend Machete::CLI::Helpers
      class << self
        def start(*argv)
          begin
            new(argv.flatten.dup).command
          rescue => e
            Machete::Log.error(e)
          end
        end

        def defaults
          @defaults ||= {}
        end
      end

      FLAG = /--?(.+)/ ## match --<name> and -<name>; captures <name>
      attr_reader :options
      attr_reader :argv

      def initialize(args=[], opts={})
        @options = opts.merge(self.class.defaults)
        @argv = args

        flags
      end

      def flags
        while(!argv.empty? && capture = FLAG.match(argv.first)) ## Parse
          # Arguments
          arg = capture[1]
          argv.shift # Discard --<name>; arg == <name>

          if(_has_option?(arg))
            _handle_option(arg)
            next
          end
          if(_has_flag?(arg))
            _handle_flag(arg)
            next
          end

          raise MacheteError, "Unhandled flag `#{arg}`!"
        end
      end

      def command
        return if(argv.empty?) ## Nothing to see here
        raise MacheteError, "Unhandled argument `#{argv.first}`!" if(!_has_subcommand?(argv.first))

        _handle_subcommand(argv.shift)
      end

      private

      def _validate(name, value, options={})
        raise MacheteError, "Argument #{name} must be a #{options[:kind_of]}" unless(!options[:kind_of].is_a?(Class) || value.is_a?(options[:kind_of]))
        raise MacheteError, "Argument #{name} must be one of #{options[:one_of]}" unless(!options[:one_of].is_a?(Array) || options[:one_of].include?(value))
      end

      def _has_option?(name)
        respond_to?("option_#{name}".to_sym)
      end

      def _handle_option(name)
        send("option_#{name}".to_sym, argv.shift)
      end

      def _has_flag?(name)
        respond_to?("flag_#{name}".to_sym)
      end

      def _handle_flag(name)
        send("flag_#{name}".to_sym)
      end

      def _has_subcommand?(name)
        respond_to?("subcommand_#{name}".to_sym) || respond_to?(name.to_sym)
      end

      def _handle_subcommand(name)
        _name = name.to_sym
        if(respond_to?(_name)) ## Instance Method
          arity = method(_name).arity # -1 --> *splat
          send(_name, *(arity < 0 ? argv : argv.shift(arity)))

        else ## Registered Sub-command
          send("subcommand_#{name}".to_sym, argv)
        end
      end
    end
  end
end
