module Redlander
  class Serializer
    # Create a new serializer.
    # Name can be either of [:rdfxml, :ntriples, :turtle, :json, :dot],
    # or nil, which defaults to :rdfxml.
    #
    # TODO: Only a small subset of parsers is implemented,
    # because the rest seem to be very buggy.
    def initialize(name = :rdfxml)
      @rdf_serializer = Redland.librdf_new_serializer(Redlander.rdf_world, name.to_s, nil, nil)
      raise RedlandError.new("Failed to create a new serializer") if @rdf_serializer.null?
      ObjectSpace.define_finalizer(self, proc { Redland.librdf_free_serializer(@rdf_serializer) })
    end

    # Serialize a model into a string.
    #
    # Options are:
    #   :base_uri   base URI (String or URI)
    def to_string(model, options = {})
      base_uri = if options.has_key?(:base_uri)
                   Uri.new(options[:base_uri]).rdf_uri
                 else
                   nil
                 end
      Redland.librdf_serializer_serialize_model_to_string(@rdf_serializer, base_uri, model.rdf_model)
    end

    # Serializes a model and stores it in a file
    # filename  -  the name of the file to serialize to
    # model     -  model instance
    #
    # Options are:
    #   :base_uri   base URI (String or URI)
    #
    # Returns true on success, or false.
    def to_file(model, filename, options = {})
      base_uri = if options.has_key?(:base_uri)
                   Uri.new(options[:base_uri]).rdf_uri
                 else
                   nil
                 end
      Redland.librdf_serializer_serialize_model_to_file(@rdf_serializer, filename, base_uri, model.rdf_model).zero?
    end
  end


  # Applied to Model
  module SerializingInstanceMethods
    def to_rdfxml(options = {})
      serializer = Serializer.new(:rdfxml)
      serializer.to_string(self, options)
    end

    def to_ntriples(options = {})
      serializer = Serializer.new(:ntriples)
      serializer.to_string(self, options)
    end

    def to_turtle(options = {})
      serializer = Serializer.new(:turtle)
      serializer.to_string(self, options)
    end

    def to_json(options = {})
      serializer = Serializer.new(:json)
      serializer.to_string(self, options)
    end

    def to_dot(options = {})
      serializer = Serializer.new(:dot)
      serializer.to_string(self, options)
    end

    # Serialize the model into a file.
    #
    # Options are:
    #   :format   - output format [:rdfxml (default), :ntriples, :turtle, :json, :dot]
    #   :base_uri - base URI
    def to_file(filename, options = {})
      serializer_options = options.dup
      serializer = Serializer.new(serializer_options.delete(:format) || :rdfxml)
      serializer.to_file(self, filename, serializer_options)
    end
  end
end
