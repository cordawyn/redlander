require 'redlander/stream'
require 'redlander/stream_enumerator'

module Redlander
  class ModelProxy
    include StreamEnumerator

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

    # Find statements satisfying the given criteria.
    # Scope can be:
    #   :all
    #   :first
    def find(scope, options = {}, &block)
      stream = Stream.new(@model, Statement.new(options))

      case scope
      when :first
        stream.current
      when :all
        stream.tail
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


    private

    def reset_stream
      @stream = Stream.new(@model)
    end
  end
end
