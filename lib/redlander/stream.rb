module Redlander
  class Stream
    attr_reader :rdf_stream

    # Convert something to an RDF stream.
    # Source can be:
    #   Model - to convert a model to an RDF stream, or
    #           if content (Statement) supplied,
    #           produce a stream of statements from the given model,
    #           matching the non-empty nodes of the given statement.
    def initialize(source, content = nil, options = {})
      @rdf_stream = case source
                    when Model
                      if content.is_a?(Statement)
                        Redland.librdf_model_find_statements(source.rdf_model, content.rdf_statement)
                      else
                        Redland.librdf_model_as_stream(source.rdf_model)
                      end
                    else
                      # TODO
                      raise NotImplementedError.new
                    end
      raise RedlandError.new("Failed to create a new stream") if @rdf_stream.null?
      ObjectSpace.define_finalizer(self, proc { Redland.librdf_free_stream(@rdf_stream) })
    end

    # End-of-stream?
    def eos?
      Redland.librdf_stream_end(@rdf_stream) != 0
    end

    # Move stream pointer forward
    def succ
      Redland.librdf_stream_next(@rdf_stream).zero?
    end

    # Current statement in the stream, or nil
    def current
      Statement.new(self) unless eos?
    end

    # Return all the remaining statements in the stream
    # from the current position.
    def tail
      [].tap do |all|
        while !eos?
          all << current
          succ
        end
      end
    end
  end
end
