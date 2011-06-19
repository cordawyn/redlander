require 'redlander/statement'

module Redlander

  class ModelProxy

    include Enumerable

    def initialize(model)
      @model = model
    end

    def each(&block)
      if block_given?
        yield iterate(initialize_model_stream, &block)
      else
        raise ::LocalJumpError.new("no block given")
      end
    end

    # Add a statement to the model.
    # It must be a complete statement - all of subject, predicate, object parts must be present.
    # Only statements that are legal RDF can be added.
    # If the statement already exists in the model, it is not added.
    #
    # Returns true on success or false on failure.
    def add(statement)
      statement.model = @model
    end

    # Create a statement and add it to the model.
    #
    # Options are:
    #   :subject, :predicate, :object,
    # (see Statement.new for option explanations).
    #
    # Returns an instance of Statement on success,
    # or nil if the statement could not be added.
    def create(options = {})
      statement = Statement.new(options)
      add(statement) && statement
    end

    def empty?
      size.zero?
    end

    def size
      s = Redland.librdf_model_size(@model.rdf_model)
      if s < 0
        raise RedlandError.new("Attempt to get size when using non-countable storage")
      else
        s
      end
    end

    # Find statements satisfying the given criteria.
    # Scope can be:
    #   :all
    #   :first
    # Note that find(:all) is "lazy", it doesn't instantiate all statements at once,
    # which makes it useable to get "chained" queries.
    def find(scope, options = {}, &block)
      statement = Statement.new(options)
      rdf_stream = Redland.librdf_model_find_statements(@model.rdf_model, statement.rdf_statement)
      ObjectSpace.define_finalizer(rdf_stream, proc {|id| puts "Destroying #{id}"; Redland.librdf_free_stream(rdf_stream) })

      case scope
      when :first
        first
      when :all
        if block_given?
          yield iterate(rdf_stream)
        else
          # TODO
          # all
        end
      else
        raise RedlandError.new("Invalid search scope '#{scope}' specified.")
      end
    end


    private

    def iterate(rdf_stream)
      while Redland.librdf_stream_end(rdf_stream).zero?
        yield current(rdf_stream)
        Redland.librdf_stream_next(rdf_stream).zero?
      end
    end

    def initialize_model_stream
      rdf_stream = Redland.librdf_model_as_stream(@model.rdf_model)
      raise RedlandError.new("Failed to create a new stream") if rdf_stream.null?
      ObjectSpace.define_finalizer(rdf_stream, proc { Redland.librdf_free_stream(rdf_stream) })
      rdf_stream
    end

    # Get the current Statement in the stream.
    def current(rdf_stream)
      rdf_statement = Redland.librdf_stream_get_object(rdf_stream)
      statement = Statement.new(rdf_statement)
      # not using Statement#model= in order to avoid re-adding the statement to the model
      statement.instance_variable_set(:@model, @model)
      statement
    end

  end

end
