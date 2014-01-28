##
# Class: Machete::Config
#
require "pathname"
require "machete"
require "machete/log"

module Machete
  class Config
    class << self
      def pwd=(p=nil)
        @pwd = Pathname.new(p) unless(p.nil?)
        @pwd ||= Pathname.new(Dir.pwd)
      end
      alias_method :pwd, :pwd=

      def conf_file=(c=nil)
        @conf_file = c unless(p.nil?)
        @conf_file ||= "Machetefile"
      end
      alias_method :conf_file, :conf_file=

      def relative(path)
        pwd.join(path)
      end

      def file_path
        pwd.join(conf_file)
      end

      def store
        pwd.join(".machete")
      end

      def from_file(root=nil, conf="Machetefile")
        pwd = root; conf_file = conf
        throw Errno::ENOENT, "Configuration could not be read from #{ file_path })!" unless File.exist?(file_path)

        ## Load Machetefile DSL
        Machete.model.instance_exec do
          eval(IO.read(Machete::Config.file_path), binding, Machete::Config.file_path.to_s, 1)
        end
        Machete::Log.info("Using #{file_path}")
      end
    end
  end
end
