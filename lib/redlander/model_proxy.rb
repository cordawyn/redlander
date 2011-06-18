require 'redlander/statement'

module Redlander

  class ModelProxy

    include StatementIterator

    def initialize(model, rdf_stream = nil)
      @model = model
      @rdf_stream = if rdf_stream
                      rdf_stream
                    else
                      Redland.librdf_model_as_stream(@model.rdf_model)
                    end
      raise RedlandError.new("Failed to create a new stream") unless @rdf_stream
      ObjectSpace.define_finalizer(@rdf_stream, proc { Redland.librdf_free_stream(@rdf_stream) })
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
    def find(scope, options = {})
      statement = Statement.new(options)
      rdf_stream = Redland.librdf_model_find_statements(@model.rdf_model, statement.rdf_statement)
      proxy = self.class.new(@model, rdf_stream)

      case scope
      when :first
        proxy.first
      when :all
        if block_given?
          proxy.each
        else
          # oh?
          proxy.map(&:dup)
        end
      else
        raise RedlandError.new("Invalid search scope '#{scope}' specified.")
      end
    end

    def all(options = {})
      find(:all, options)
    end

  end

end
