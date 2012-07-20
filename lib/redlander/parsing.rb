module Redlander
  # Syntax parsing methods.
  # "self" is assumed to be an instance of Redlander::Model
  module Parsing
    # Core parsing method for non-streams
    #
    # @param [String] content
    #    Can be a String,
    #      causing the statements to be extracted
    #      directly from it,
    #    or URI (or Redlander::Uri)
    #      causing the content to be first pulled
    #      from the specified URI (or a local file,
    #      if URI schema == "file:")
    # @param [Hash{Symbol => String}] options
    #   :name  - name of the parser to use
    #   :mime_type - MIME type of the syntax, if applicable
    #   :type_uri - URI of syntax, if applicable (String, URI or Redlander::Uri)
    #   :base_uri - base URI (String, URI or Redlander::Uri),
    #               required for URI parsing (see "content" parameter)
    #
    # If a block is given, the extracted statements will be yielded into
    # the block and inserted into the model depending on the output
    # of the block (if true, the statement will be added,
    # if false, the statement will not be added).
    def from(content, options = {})
      name = options[:name].to_s
      mime_type = options[:mime_type] && options[:mime_type].to_s
      type_uri = options[:type_uri] && options[:type_uri].to_s
      base_uri = options[:base_uri] && options[:base_uri].to_s
      content = Uri.new(content) if content.is_a?(URI)

      # FIXME: to be fixed in librdf:
      # ntriples parser absolutely needs "\n" at the end of the input
      if name == "ntriples" && !content.is_a?(Uri) && !content.end_with?("\n")
        content << "\n"
      end

      rdf_parser = Redland.librdf_new_parser(Redlander.rdf_world, name, mime_type, type_uri)
      raise RedlandError, "Failed to create a new '#{name}' parser" if rdf_parser.null?

      if block_given?
        begin
          rdf_stream =
            if content.is_a?(Uri)
              Redland.librdf_parser_parse_as_stream(rdf_parser, content.rdf_uri, base_uri)
            else
              Redland.librdf_parser_parse_string_as_stream(rdf_parser, content, base_uri)
            end
          raise RedlandError, "Failed to create a new stream" if rdf_stream.null?

          while Redland.librdf_stream_end(rdf_stream).zero?
            statement = Statement.new(Redland.librdf_stream_get_object(rdf_stream))
            statements.add(statement) if yield statement
            Redland.librdf_stream_next(rdf_stream)
          end
        ensure
          Redland.librdf_free_stream(rdf_stream)
        end
      else
        if content.is_a?(Uri)
          Redland.librdf_parser_parse_into_model(rdf_parser, content.rdf_uri, base_uri, @rdf_model).zero?
        else
          Redland.librdf_parser_parse_string_into_model(rdf_parser, content, base_uri, @rdf_model).zero?
        end
      end
    ensure
      Redland.librdf_free_parser(rdf_parser)
    end

    def from_rdfxml(content, options = {}, &block)
      from(content, options.merge(:name => "rdfxml"), &block)
    end

    def from_ntriples(content, options = {}, &block)
      from(content, options.merge(:name => "ntriples"), &block)
    end

    def from_turtle(content, options = {}, &block)
      from(content, options.merge(:name => "turtle"), &block)
    end

    def from_uri(uri, options = {}, &block)
      if uri.is_a?(String)
        uri = URI.parse(uri)
        uri = URI.parse("file://#{File.expand_path(uri.to_s)}") if uri.scheme.nil?
      end
      from(uri, options, &block)
    end
    alias_method :from_file, :from_uri
  end
end
