require 'redlander/statement'

module Redlander

  class ParserProxy

    include StatementIterator

    def initialize(parser, content, options = {})
      @model = nil  # the yielded statements will not be bound to a model
      @rdf_stream = Redland.librdf_parser_parse_string_as_stream(parser.rdf_parser, content, Redlander.to_rdf_uri(options[:base_uri]))
      raise RedlandError.new("Failed to create a new stream") if @rdf_stream.null?
      ObjectSpace.define_finalizer(@rdf_stream, proc { Redland.librdf_free_stream(@rdf_stream) })
    end

  end

end
