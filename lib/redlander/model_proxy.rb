module Redlander
  class ModelProxy
    include Enumerable

    # @param [Redlander::Model] model
    def initialize(model)
      @model = model
    end

    # Add a statement to the model.
    # It must be a complete statement - all of subject, predicate, object parts must be present.
    # Only statements that are legal RDF can be added.
    # If the statement already exists in the model, it is not added.
    #
    # @return [true, false]
    def add(statement)
      Redland.librdf_model_add_statement(@model.rdf_model, statement.rdf_statement).zero?
    end
    alias_method :<<, :add

    # Delete a statement from the model,
    # or delete all statements matching the given criteria.
    #
    # @param [Statement, Hash] source
    #   - for a Hash all keys are optional:
    #     :subject
    #     :predicate
    #     :object
    # A missing hash key or a statement with a nil node
    # matches all corresponding nodes in the statements.
    #
    # @return [true, false]
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
    # @return [Statement, nil]
    def create(options = {})
      statement = Statement.new(options)
      add(statement) ? statement : nil
    end

    # Checks whether there are no statements in the model.
    #
    # @return [true, false]
    def empty?
      size.zero?
    end

    # Size of the model in statements.
    #
    # Note the difference between #size and #count:
    # While #count must iterate across all statements in the model,
    # #size tries to use a more efficient C implementation.
    # So #size should be preferred to #count in terms of performance.
    # However, for non-countable storages, #size falls back to
    # using #count. Also, #size is not available for enumerables
    # (e.g. produced from #each (without a block) or otherwise).
    #
    # @return [Fixnum]
    def size
      s = Redland.librdf_model_size(@model.rdf_model)
      s < 0 ? count : s
    end

    # Enumerate (and filter) model statements.
    #
    # @param [Statement, Hash, nil] *args
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

    # Find a first statement matching the given criteria.
    # (Shortcut for "find(:first, options)").
    #
    # @return [Statement, nil]
    def first(options = {})
      find(:first, options)
    end

    # Find all statements matching the given criteria.
    # (Shortcut for "find(:all, options)").
    #
    # @return [Array]
    def all(options = {})
      find(:all, options)
    end
  end
end
