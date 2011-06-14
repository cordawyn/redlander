module Redlander

  # Wrapper for a librdf_stream object.
  module StatementIterator

    include Enumerable

    # Iterate over statements in the stream.
    def each(&block)
      # TODO: The options specify matching criteria: subj, pred, obj;
      #   if an option is not specified, it matches any value,
      #   so with no options given, all statements will be returned.
      if block_given?
        while Redland.librdf_stream_end(@rdf_stream).zero?
          yield current
          Redland.librdf_stream_next(@rdf_stream).zero?
        end
      else
        raise ::LocalJumpError.new("no block given")
      end
    end


    private

    # Get the current Statement in the stream.
    def current
      rdf_statement = Redland.librdf_stream_get_object(@rdf_stream)
      statement = Statement.new(rdf_statement)
      # not using Statement#model= in order to avoid re-adding the statement to the model
      statement.instance_variable_set(:@model, @model)
      statement
    end

  end

end
