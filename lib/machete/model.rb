##
# Class: Machete::Model
#

require "json"
require "machete/config"
require "machete/log"
require "machete/model/helpers"
require "machete/model/cookbook"
require "machete/model/environment"
require "machete/model/universe"

module Machete
  class Model
    extend Machete::Model::Helpers
    def initialize()
      @cookbooks = Machete::Model::Cookbooks.new(self)
      @environments = Machete::Model::Environments.new(self).load_files
      @universes = Machete::Model::Universes.new(self)
      @default_universe = "_default"
    end

    dispatch :log_level, Machete::Log, :level
    dispatch :file_path, Machete::Config
    dispatch :chef_api, :cookbooks
    dispatch :cookbook, :cookbooks
    dispatch :site, :cookbooks
    dispatch :environment, :environments
    dispatch :universe, :universes
    attr_reader :cookbooks
    attr_reader :environments
    attr_reader :universes

    ## Change the name of the default universe
    def default_universe(name=nil)
      @default_universe = name unless(name.nil?)
      @default_universe
    end

    export :cookbooks, :environments, :universes

    def to_json
      JSON.pretty_generate(to_hash)
    end

    ## Dispatch everything else to the _default universe
    dispatch :method_missing, :default, :send

    def default
      @universes[@default_universe] ||= Machete::Model::Universe.new(@default_universe, self)
    end
  end
end
