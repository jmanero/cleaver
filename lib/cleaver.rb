##
# Class: Cleaver
#
require "colorize"
require "pathname"
require "cleaver/tasks"

##
# Cleaver
##
module Cleaver
  ##
  # Cleaver Error
  ##
  class Error < StandardError
    ## Don't print traces for these
  end

  class << self
    ## Logging
    def log
      @logger ||= begin
        logger = Logger.new(STDOUT)
        logger.level = Logger::INFO
        logger.formatter = method(:log_formatter)

        logger
      end
    end
    alias_method :logger, :log

    def log_formatter(severity, datetime, progname, msg)
      color = case severity
        when "DEBUG" then :cyane
        when "INFO" then :green
        when "WARN" then :yellow
        when "ERROR" then :red
        else :white
      end
      "[#{ datetime }] ".white + "#{ severity }: #{ msg }\n".send(color)
    end

    ## File paths
    def directory
      @directory ||= Pathname.new(Dir.pwd)
    end

    def file
      directory.join("Cleaverfile")
    end

    def store
      directory.join(".cleaver")
    end
  end
end
