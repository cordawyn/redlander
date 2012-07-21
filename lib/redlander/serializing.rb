module Redlander
  # Syntax parsing methods.
  # "self" is assumed to be an instance of Redlander::Model
  module Serializing
    # Serialize model into a string
    #
    # @param [Hash{Symbol => String}] options
    #   :name  - name of the serializer to use
    #   :mime_type - MIME type of the syntax, if applicable
    #   :type_uri - URI of syntax, if applicable (String, URI or Redlander::Uri)
    #   :base_uri - base URI (String, URI or Redlander::Uri),
    #               required for URI parsing (see "content" parameter)
    def to(options = {})
      name = options[:name].to_s
      mime_type = options[:mime_type] && options[:mime_type].to_s
      type_uri = options[:type_uri] && options[:type_uri].to_s
      base_uri = options[:base_uri] && options[:base_uri].to_s

      rdf_serializer = Redland.librdf_new_serializer(Redlander.rdf_world, name, mime_type, type_uri)
      raise RedlandError.new("Failed to create a new serializer") if rdf_serializer.null?

      begin
        if options[:file]
          Redland.librdf_serializer_serialize_model_to_file(rdf_serializer, options[:file], base_uri, @rdf_model).zero?
        else
          Redland.librdf_serializer_serialize_model_to_string(rdf_serializer, base_uri, @rdf_model)
        end
      ensure
        Redland.librdf_free_serializer(rdf_serializer)
      end
    end

    def to_rdfxml(options = {})
      to(options.merge(:name => "rdfxml"))
    end

    def to_ntriples(options = {})
      to(options.merge(:name => "ntriples"))
    end

    def to_turtle(options = {})
      to(options.merge(:name => "turtle"))
    end

    def to_json(options = {})
      to(options.merge(:name => "json"))
    end

    def to_dot(options = {})
      to(options.merge(:name => "dot"))
    end

    def to_file(filename, options = {})
      to(options.merge(:file => filename))
    end
  end
end
