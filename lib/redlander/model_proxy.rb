module Redlander
  class ModelProxy
    include Enumerable

    def initialize(model)
      @model = model
    end

    # Add a statement to the model.
    # It must be a complete statement - all of subject, predicate, object parts must be present.
    # Only statements that are legal RDF can be added.
    # If the statement already exists in the model, it is not added.
    #
    # Returns true on success or false on failure.
    def add(statement)
      Redland.librdf_model_add_statement(@model.rdf_model, statement.rdf_statement).zero?
    end
    alias_method :<<, :add

    # Delete a statement from the model,
    # or delete all statements matching the given criteria.
    # Source can be either
    #   Statement
    # or
    #   Hash (all keys are optional)
    #     :subject
    #     :predicate
    #     :object
    def delete(source)
      statement = case source
                  when Statement
                    source
                  when Hash
                    Statement.new(source)
                  else
                    # TODO
                    raise NotImplementedError.new
                  end
      Redland.librdf_model_remove_statement(@model.rdf_model, statement.rdf_statement).zero?
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

    # Enumerate (and filter) model statements.
    #
    # @param [Statement, Hash, NilClass] *args
    #   - if given Statement or Hash, filter the model statements
    #     according to the specified pattern.
    #
    # If given no block, returns Enumerator.
    def each(*args)
      if block_given?
        rdf_stream =
          if args.empty?
            Redland.librdf_model_as_stream(@model.rdf_model)
          else
            pattern = Statement.new(args.first)
            Redland.librdf_model_find_statements(@model.rdf_model, pattern.rdf_statement)
          end
        raise RedlandError, "Failed to create a new stream" if rdf_stream.null?

        begin
          while Redland.librdf_stream_end(rdf_stream).zero?
            statement = Statement.new(Redland.librdf_stream_get_object(rdf_stream))
            yield statement
            Redland.librdf_stream_next(rdf_stream)
          end
        ensure
          Redland.librdf_free_stream(rdf_stream)
        end
      else
        enum_for(:each, *args)
      end
    end

    # Find statements satisfying the given criteria.
    # Scope can be:
    #   :all
    #   :first
    def find(scope, options = {})
      case scope
      when :first
        each(options).first
      when :all
        each(options).to_a
      else
        raise RedlandError.new("Invalid search scope '#{scope}' specified.")
      end
    end

    def first(options = {})
      find(:first, options)
    end

    def all(options = {})
      find(:all, options)
    end
  end
end
