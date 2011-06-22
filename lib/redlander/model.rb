module Redlander
  class Model
    include Redlander::ParsingInstanceMethods
    include Redlander::SerializingInstanceMethods

    attr_reader :rdf_model

    # Create a new RDF model.
    # For explanation of options, read Storage.initialize
    def initialize(options = {})
      @storage = Storage.new(options)

      @rdf_model = Redland.librdf_new_model(Redlander.rdf_world, @storage.rdf_storage, "")
      raise RedlandError.new("Failed to create a new model") if @rdf_model.null?
      ObjectSpace.define_finalizer(self, proc { Redland.librdf_free_model(@rdf_model) })
    end

    # Statements contained in the model.
    #
    # Similar to Ruby on Rails, a proxy object is actually returned,
    # which delegates methods to Statement class.
    def statements
      ModelProxy.new(self)
    end

    # Wrap changes to the given model in a transaction.
    # If an exception is raised in the block, the transaction is rolled back.
    # (Does not work for all storages, in which case the changes are instanteous).
    def transaction
      if block_given?
        Redland.librdf_model_transaction_start(@rdf_model).zero? || RedlandError.new("Failed to initialize a transaction")
        yield
        Redland.librdf_model_transaction_commit(@rdf_model).zero? || RedlandError.new("Failed to commit the transaction")
      end
    rescue
      rollback
      raise
    end

    # Rollback the transaction
    def rollback
      Redland.librdf_model_transaction_rollback(@rdf_model).zero? || RedlandError.new("Failed to rollback the latest transaction")
    end
  end
end
