require 'redlander/storage'
require 'redlander/model_proxy'

module Redlander

  class Model

    include Redlander::ParsingInstanceMethods
    include Redlander::SerializingInstanceMethods

    attr_reader :rdf_model

    # Create a new RDF model.
    # For explanation of options, read Storage.initialize_storage
    def initialize(options = {})
      @rdf_storage = Storage.initialize_storage(options)

      @rdf_model = Redland.librdf_new_model(Redlander.rdf_world, @rdf_storage, "")
      raise RedlandError.new("Failed to create a new model") unless @rdf_model
      ObjectSpace.define_finalizer(@rdf_model, proc { Redland.librdf_free_model(@rdf_model) })
    end

    # Statements contained in the model.
    #
    # Similar to Ruby on Rails, a proxy object is actually returned,
    # which delegates methods to Statement class.
    def statements
      ModelProxy.new(self)
    end

  end

end
