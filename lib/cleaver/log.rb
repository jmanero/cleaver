##
# Class: Cleaver::Log
#
require "berkshelf"
require "colorize"
require "growl"
require "json"

module Cleaver
  module Log
    LEVELS = [ :debug, :info, :warn, :error ]

    module Console
      COLORS = {
        :debug => :cyan,
        :info => :green,
        :warn => :yellow,
        :error =>  :red
      }

      class << self
        def render(l, m, trace=nil)
          mcolor = _color(l.to_sym)
          puts "[#{ Time.now }] ".white + "Cleaver (#{ l }): ".magenta + m.send(mcolor)
          trace.each{|t| puts "    #{ t }".send(mcolor) } unless(trace.nil?)
        end
        private

        def _color(l)
          COLORS[l] || :default
        end
      end
    end

    class << self
      def log(l, m, trace=nil)
        return unless(LEVELS.index(l.to_sym) >= _level rescue false)
        formatter.render(l, m, trace)
      end

      def error(e)
        case e
          when CleaverError
            log(LEVELS.last, e.message)
          when Exception
            log(LEVELS.last, "#{ e.class }: #{ e.message }", e.backtrace)
          else
            log(LEVELS.last, e)
        end
      end

      ## Auto-handle custom levels
      def method_missing(m, *args)
        super unless(LEVELS.include?(m))
        Cleaver::Log.log(m, *args)
      end

      def notify(from, message)
        Log.info(message)

        return unless(Growl.installed?)
        Growl.notify message, :icon => File.expand_path("../../doc/icon_small.png", File.dirname(__FILE__)), :title => "Cleaver - #{ from }"
      end

      def level=(value=nil)
        unless(value.nil? || !LEVELS.include?(value.to_sym))
          @level = LEVELS.index(value.to_sym)
          log(:info, "Setting log level to #{ value }")
        end

        LEVELS[_level]
      end
      alias_method :level, :level=

      def formatter=(value=nil)
        @formatter = value.to_sym unless(value.nil?)
        @formatter ||= Cleaver::Log::Console
      end
      alias_method :formatter, :formatter=

      private

      def _level
        @level ||= 1 ## Default :info
      end

      #      def _format_json(mlevel, msg, trace=nil)
      #        output = {
      #          :timestamp => Time.now,
      #          :level => mlevel,
      #          :message => msg
      #        }
      #        output[:trace] = trace unless(trace.nil?)
      #
      #        JSON.generate(output)
      #      end
    end
  end
end

## Hijack the Berkshelf logger
module Berkshelf::UI
  def say(message="", *args)
    Cleaver::Log.log(:debug, message)
  end

  def info(message="", *args)
    Cleaver::Log.log(:info, message)
  end

  def warn(message="", *args)
    Cleaver::Log.log(:warn, message)
  end

  def error(message="", *args)
    Cleaver::Log.log(:error, message)
  end
end
