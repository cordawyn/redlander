module Redlander
  # Proxy between model and its statements,
  # allowing to scope actions on statements
  # within a certain model.
  #
  # @example
  #   model = Redlander::Model.new
  #   model.statements
  #   # => ModelProxy
  #   model.statements.add(...)
  #   model.statements.each(...)
  #   model.statements.find(...)
  #   # etc...
  class ModelProxy
    include Enumerable

    # @param [Redlander::Model] model
    def initialize(model)
      @model = model
    end

    # Add a statement to the model.
    #
    # @note
    #   All of subject, predicate, object nodes of the statement must be present.
    #   Only statements that are legal RDF can be added.
    #   If the statement already exists in the model, it is not added.
    #
    # @param [Statement] statement
    # @return [Boolean]
    def add(statement)
      Redland.librdf_model_add_statement(@model.rdf_model, statement.rdf_statement).zero?
    end
    alias_method :<<, :add

    # Delete a statement from the model.
    #
    # @note
    #   All of subject, predicate, object nodes of the statement must be present.
    #
    # @param [Statement] statement
    # @return [Boolean]
    def delete(statement)
      Redland.librdf_model_remove_statement(@model.rdf_model, statement.rdf_statement).zero?
    end

    # Delete all statements from the model,
    # matching the given pattern
    #
    # @param [Statement, Hash] pattern (see {#find})
    # @return [Boolean]
    def delete_all(pattern = {})
      each(pattern) { |st| delete(st) }
    end

    # Create a statement and add it to the model.
    #
    # @param [Hash] source subject, predicate and object nodes
    #   of the statement to be created (see Statement#initialize).
    # @option source [Node, URI, String, nil] :subject
    # @option source [Node, URI, String, nil] :predicate
    # @option source [Node, URI, String, nil] :object
    # @return [Statement, nil]
    def create(source)
      statement = Statement.new(source)
      add(statement) ? statement : nil
    end

    # Checks whether there are no statements in the model.
    #
    # @return [Boolean]
    def empty?
      size.zero?
    end

    # Checks the existence of statements in the model
    # matching the given criteria
    #
    # @param [Hash, Statement] pattern (see {#find})
    # @return [Boolean]
    def exist?(pattern)
      !first(pattern).nil?
    end

    # Size of the model in statements.
    #
    # @note
    #   While #count must iterate across all statements in the model,
    #   {#size} tries to use a more efficient C implementation.
    #   So {#size} should be preferred to #count in terms of performance.
    #   However, for non-countable storages, {#size} falls back to
    #   using #count. Also, {#size} is not available for enumerables
    #   (e.g. produced from {#each} (without a block) or otherwise) and
    #   thus cannot be used to count "filtered" results.
    #
    # @return [Fixnum]
    def size
      s = Redland.librdf_model_size(@model.rdf_model)
      s < 0 ? count : s
    end

    # Enumerate (and filter) model statements.
    # If given no block, returns Enumerator.
    #
    # @param [Statement, Hash, void] args
    #   if given Statement or Hash, filter the model statements
    #   according to the specified pattern (see {#find} pattern).
    # @yieldparam [Statement]
    # @return [void]
    def each(*args)
      if block_given?
        rdf_stream =
          if args.empty?
            Redland.librdf_model_as_stream(@model.rdf_model)
          else
            pattern = args.first.is_a?(Statement) ? args.first.rdf_statement : Statement.new(args.first)
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
    #
    # @param [:first, :all] scope find just one or all matches
    # @param [Hash, Statement] pattern matching pattern made of:
    #   - Hash with :subject, :predicate or :object nodes, or
    #   - "patternized" Statement (nil nodes are matching anything).
    # @return [Statement, Array, nil]
    def find(scope, pattern = {})
      case scope
      when :first
        each(pattern).first
      when :all
        each(pattern).to_a
      else
        raise RedlandError, "Invalid search scope '#{scope}' specified."
      end
    end

    # Find a first statement matching the given criteria.
    # (Shortcut for {#find}(:first, pattern)).
    #
    # @param [Statement, Hash] pattern (see {#find})
    # @return [Statement, nil]
    def first(pattern = {})
      find(:first, pattern)
    end

    # Find all statements matching the given criteria.
    # (Shortcut for {#find}(:all, pattern)).
    #
    # @param [Statement, Hash] pattern (see {#find})
    # @return [Array<Statement>]
    def all(pattern = {})
      find(:all, pattern)
    end
  end
end
