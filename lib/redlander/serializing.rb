module Redlander
  # Syntax parsing methods.
  # "self" is assumed to be an instance of Redlander::Model
  module Serializing
    # Serialize model into a string
    #
    # @param [Hash] options
    # @option options [String] :name name of the serializer to use,
    # @option options [String] :mime_type MIME type of the syntax, if applicable,
    # @option options [String, URI, Uri] :type_uri URI of syntax, if applicable,
    # @option options [String, URI, Uri] :base_uri base URI,
    #   to be applied to the nodes with relative URIs.
    # @raise [RedlandError] if it fails to create a serializer
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

    # Serialize the model in RDF/XML format.
    # Shortcut for {#to}(:name => "rdfxml").
    #
    # @param (see #to)
    # @return [String]
    def to_rdfxml(options = {})
      to(options.merge(:name => "rdfxml"))
    end

    # Serialize the model in NTriples format.
    # Shortcut for {#to}(:name => "ntriples").
    #
    # @param (see #to)
    # @return [String]
    def to_ntriples(options = {})
      to(options.merge(:name => "ntriples"))
    end

    # Serialize the model in Turtle format.
    # Shortcut for {#to}(:name => "turtle").
    #
    # @param (see #to)
    # @return [String]
    def to_turtle(options = {})
      to(options.merge(:name => "turtle"))
    end

    # Serialize the model in JSON format.
    # Shortcut for {#to}(:name => "json").
    #
    # @param (see #to)
    # @return [String]
    def to_json(options = {})
      to(options.merge(:name => "json"))
    end

    # Serialize the model in Dot format.
    # Shortcut for {#to}(:name => "dot").
    #
    # @param (see #to)
    # @return [String]
    def to_dot(options = {})
      to(options.merge(:name => "dot"))
    end

    # Serialize the model to a file.
    # Shortcut for {#to}(:name => "rdfxml").
    #
    # @param [String] filename path to the output file
    # @param [Hash] options (see {#to} options)
    # @return [void]
    def to_file(filename, options = {})
      to(options.merge(:file => filename))
    end
  end
end
