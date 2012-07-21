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
    # (For available storage options see http://librdf.org/docs/api/redland-storage-modules.html)
    #
    # @param [Hash] options
    # @option options [String] :storage
    #   - "memory"     - default, if :storage option is omitted,
    #   - "hashes"
    #   - "file"       - memory model initialized from RDF/XML file,
    #   - "uri"        - read-only memory model with URI provided in 'name' arg,
    #   - "mysql"
    #   - "sqlite"
    #   - "postgresql"
    #   - "tstore"
    #   - "virtuoso"
    #   - ... anything else that Redland can handle.
    # @option options [String] :name storage identifier (DB file name or database name),
    # @option options [String] :host database host name (for store types: :postgres, :mysql, :tstore),
    # @option options [String] :port database host port (for store types: :postgres, :mysql, :tstore),
    # @option options [String] :database database name (for store types: :postgres, :mysql, :tstore),
    # @option options [String] :user database user name (for store types: :postgres, :mysql, :tstore),
    # @option options [String] :password database user password (for store types: :postgres, :mysql, :tstore),
    # @option options [String] :hash_type hash type (for store types: :bdb),
    #   can be either 'memory' or 'bdb',
    # @option options [String] :new force creation of a new store,
    # @option options [String] :dir directory path (for store types: :hashes),
    # @option options [String] :contexts support contexts (for store types: :hashes, :memory),
    # @option options [String] :write allow writing data to the store (for store types: :hashes),
    # @option options [...] ... other storage-specific options.
    # @raise [RedlandError] if it fails to create a storage or a model.
    def initialize(options = {})
      options = options.dup
      storage_type = options.delete(:storage) || "memory"
      storage_name = options.delete(:name)

      @rdf_storage = Redland.librdf_new_storage(Redlander.rdf_world,
                                                storage_type.to_s,
                                                storage_name.to_s,
                                                Redlander.to_rdf_options(options))
      raise RedlandError, "Failed to initialize '#{storage_name}' storage (type: #{storage_type})" if @rdf_storage.null?
      ObjectSpace.define_finalizer(self, proc { Redland.librdf_free_storage(@rdf_storage) })

      @rdf_model = Redland.librdf_new_model(Redlander.rdf_world, @rdf_storage, "")
      raise RedlandError, "Failed to create a new model" if @rdf_model.null?
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
    #
    # @note Does not work for all storages, in which case the changes are instanteous
    #
    # @yieldparam [void]
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
    # @return [true]
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
    # @return [true]
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
    # @return [true]
    def transaction_rollback!
      raise RedlandError, "Failed to rollback the latest transaction" unless transaction_rollback
    end
  end
end
