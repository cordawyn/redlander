require 'redlander/storage'
require 'redlander/parsing'
require 'redlander/serializing'
require 'redlander/model_proxy'

module Redlander
  # The core object incorporating the repository of RDF statements.
  class Model
    include Redlander::Parsing
    include Redlander::Serializing

    # @api private
    attr_reader :rdf_model

    # Create a new RDF model.
    #
    # @param [Hash] options (see Storage#initialize)
    # @raise [RedlandError] if it fails to create a model.
    def initialize(options = {})
      # TODO: get rid of Storage, use the low-level API
      @storage = Storage.new(options)

      @rdf_model = Redland.librdf_new_model(Redlander.rdf_world, @storage.rdf_storage, "")
      raise RedlandError.new("Failed to create a new model") if @rdf_model.null?
      ObjectSpace.define_finalizer(self, proc { Redland.librdf_free_model(@rdf_model) })
    end

    # Statements contained in the model.
    #
    # Similar to Ruby on Rails, a proxy object is actually returned,
    # which delegates methods to Statement class.
    #
    # @return [ModelProxy]
    def statements
      ModelProxy.new(self)
    end

    # Wrap changes to the given model in a transaction.
    # If an exception is raised in the block, the transaction is rolled back.
    # (Does not work for all storages, in which case the changes are instanteous).
    #
    # @yield [void]
    # @return [void]
    def transaction
      if block_given?
        transaction_start
        yield
        transaction_commit
      end
    rescue
      transaction_rollback
      raise
    end

    # Start a transaction, if it is supported by the backend storage.
    #
    # @return [Boolean]
    def transaction_start
      Redland.librdf_model_transaction_start(@rdf_model).zero?
    end

    # Start a transaction.
    #
    # @raise [RedlandError] if it is not supported by the backend storage
    def transaction_start!
      raise RedlandError, "Failed to initialize a transaction" unless transaction_start
    end

    # Commit a transaction, if it is supported by the backend storage.
    #
    # @return [Boolean]
    def transaction_commit
      Redland.librdf_model_transaction_commit(@rdf_model).zero?
    end

    # Commit a transaction.
    #
    # @raise [RedlandError] if it is not supported by the backend storage
    def transaction_commit!
      raise RedlandError, "Failed to commit the transaction" unless transaction_commit
    end

    # Rollback a transaction, if it is supported by the backend storage.
    #
    # @return [Boolean]
    def transaction_rollback
      Redland.librdf_model_transaction_rollback(@rdf_model).zero?
    end

    # Rollback a transaction.
    #
    # @raise [RedlandError] if it is not supported by the backend storage
    def transaction_rollback!
      raise RedlandError, "Failed to rollback the latest transaction" unless transaction_rollback
    end
  end
end
