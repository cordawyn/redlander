require 'redlander/parser_proxy'

module Redlander

  class Parser

    attr_reader :rdf_parser

    # Create a new parser.
    # Name can be either of [:rdfxml, :ntriples, :turtle],
    # or nil, which defaults to :rdfxml.
    #
    # TODO: Only a small subset of parsers is implemented,
    # because the rest seem to be very buggy.
    def initialize(name = :rdfxml)
      # name, mime-type and syntax uri can all be nil, which defaults to :rdfxml parser
      @rdf_parser = Redland.librdf_new_parser(Redlander.rdf_world, name.to_s, nil, nil)
      raise RedlandError.new("Failed to create a new parser") if @rdf_parser.null?
      ObjectSpace.define_finalizer(@rdf_parser, proc { Redland.librdf_free_parser(@rdf_parser) })
    end

    # Parse the content (String) into the model.
    #
    # Options are:
    #   :base_uri   base URI (String or URI)
    #
    # Returns true on success, or false.
    def from_string(model, content, options = {})
      # FIXME: A bug (?) in Redland breaks NTriples parser if its input is not terminated with "\n"
      content.concat("\n") unless content.end_with?("\n")
      Redland.librdf_parser_parse_string_into_model(@rdf_parser, content, Uri.new(options[:base_uri]).rdf_uri, model.rdf_model).zero?
    end

    # Parse the content from URI into the model.
    # (It is possible to use "file:" schema for local files).
    #
    # Options are:
    #   :base_uri   base URI (String or URI)
    #
    # Returns true on success, or false.
    def from_uri(model, uri, options = {})
      uri = URI.parse(uri)
      uri = URI.parse("file://#{File.expand_path(uri.to_s)}") if uri.scheme.nil?
      Redland.librdf_parser_parse_into_model(@rdf_parser, Uri.new(uri).rdf_uri, Redlander.to_rdf_uri(options[:base_uri]), model.rdf_model).zero?
    end
    alias_method :from_file, :from_uri

    def statements(content, options = {})
      # BUG: Parser accumulates data from consequent runs??? WTF, Redland?!
      #   When parsing a series of files, parser reported a duplicate entry,
      #   then seemed to have stopped yielding statements at all.

      # FIXME: A bug (?) in Redland breaks NTriples parser if its input is not terminated with "\n"
      content.concat("\n") unless content.end_with?("\n")
      ParserProxy.new(self, content, options)
    end

  end


  module ParsingInstanceMethods

    def from_rdfxml(content, options = {})
      parser = Parser.new(:rdfxml)
      parser.from_string(self, content, options)
    end

    def from_ntriples(content, options = {})
      parser = Parser.new(:ntriples)
      parser.from_string(self, content, options)
    end

    def from_turtle(content, options = {})
      parser = Parser.new(:turtle)
      parser.from_string(self, content, options)
    end

    # Load the model from an URI content.
    #
    # Options are:
    #   :format   - content format [:rdfxml (default), :ntriples, :turtle]
    #   :base_uri - base URI
    def from_uri(uri, options = {})
      parser_options = options.dup
      parser = Parser.new(parser_options.delete(:format) || :rdfxml)
      parser.from_uri(self, uri, parser_options)
    end
    alias_method :from_file, :from_uri

  end

end
