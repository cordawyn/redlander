require 'uri'
require 'xml_schema'
require 'redland'
require 'redlander/version'

require "redlander/exceptions"
require 'redlander/uri'
require 'redlander/node'
require 'redlander/model'
require 'redlander/statement'

# Main Redlander namespace
module Redlander
  class << self

    # @api private
    def rdf_world
      unless @rdf_world
        @rdf_world = Redland.librdf_new_world
        raise RedlandError, "Could not create a new RDF world" if @rdf_world.null?
        ObjectSpace.define_finalizer(self, self.finalize(@rdf_world))
        Redland.librdf_world_open(@rdf_world)
      end
      @rdf_world
    end


    # @api private
    # Convert options hash into a string for librdf.
    # What it does:
    #   1) Convert boolean values into 'yes/no' values
    #   2) Change underscores in key names into dashes ('dhar_ma' => 'dhar-ma')
    #   3) Join all options as "key='value'" pairs in a comma-separated string
    #
    # @example
    #   to_rdf_options {:key => true, "key_board" => 3}
    #   # => "key='yes',key-board='3'"
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

    # @api private
    def finalize(rdf_world_ptr)
      proc {
        Redland.librdf_free_world(rdf_world_ptr)
      }
    end
  end
end
