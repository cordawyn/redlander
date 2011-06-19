$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'uri'
require 'xml_schema'

module Redlander
  require 'redland'
  require 'redlander/version'

  class RedlandError < RuntimeError; end

  class << self
    def rdf_world
      unless @rdf_world
        @rdf_world = Redland.librdf_new_world
        raise RedlandError.new("Could not create a new RDF world") if @rdf_world.null?
        ObjectSpace.define_finalizer(self, proc { Redland.librdf_free_world(@rdf_world) })
        Redland.librdf_world_open(@rdf_world)
      end
      @rdf_world
    end

    # Convert options hash into a string for librdf.
    # What it does:
    #   1) Convert boolean values into 'yes/no' values
    #   2) Change underscores in key names into dashes ('dhar_ma' => 'dhar-ma')
    #   3) Join all options as "key='value'" pairs in a comma-separated string
    def to_rdf_options(options = {})
      options.inject([]){|opts, option_pair|
        key = option_pair[0].to_s.gsub(/_/, '-')
        value = if [TrueClass, FalseClass].include?(option_pair[1].class)
                  option_pair[1] ? 'yes' : 'no'
                else
                  option_pair[1]
                end
        opts << "#{key}='#{value}'"
      }.join(',')
    end
  end

  require 'redlander/error_container'
  require 'redlander/statement_iterator'
  require 'redlander/parser'
  require 'redlander/serializer'
  require 'redlander/model'
  require 'redlander/node'
end
