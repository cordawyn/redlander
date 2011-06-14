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
        raise RedlandError.new("Could not create a new RDF world") unless @rdf_world
        ObjectSpace.define_finalizer(@rdf_world, proc { Redland.librdf_free_world(@rdf_world) })
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

    # Helper method to create an instance of rdfuri.
    # For internal use only!
    def to_rdf_uri(uri)
      return nil if uri.nil?
      uri = uri.is_a?(URI) ? uri.to_s : uri
      rdf_uri = Redland.librdf_new_uri(rdf_world, uri)
      raise RedlandError.new("Failed to create URI from '#{uri}'") unless rdf_uri
      ObjectSpace.define_finalizer(rdf_uri, proc { Redland.librdf_free_uri(rdf_uri) })
      rdf_uri
    end

  end

  require 'redlander/error_container'
  require 'redlander/statement_iterator'
  require 'redlander/parser'
  require 'redlander/serializer'
  require 'redlander/model'
  require 'redlander/node'
end
