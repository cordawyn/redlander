module Redlander

  module Storage

    VALID_STORAGE_TYPES = [:memory, :hashes, :file, :uri, :tstore, :mysql, :sqlite, :postgresql]

    # Creates a store of the given type
    #
    # Store types (:storage option) are:
    #   :memory
    #   :hashes
    #   :file       - memory model initialized from RDF/XML file
    #   :uri        - read-only memory model with URI provided in 'name' arg
    #   :mysql
    #   :sqlite
    #   :postgresql
    #   :tstore
    # Options are:
    #   :name       - ?
    #   :host       - database host name (for store types: :postgres, :mysql, :tstore)
    #   :port       - database host port (for store types: :postgres, :mysql, :tstore)
    #   :database   - database name (for store types: :postgres, :mysql, :tstore)
    #   :user       - database user name (for store types: :postgres, :mysql, :tstore)
    #   :password   - database user password (for store types: :postgres, :mysql, :tstore)
    #   :hash_type  - hash type (for store types: :bdb)
    #                 can be either 'memory' or 'bdb'
    #   :new        - force creation of a new store
    #   :dir        - directory path (for store types: :hashes)
    #   :contexts   - support contexts (for store types: :hashes, :memory)
    #   :write      - allow writing data to the store (for store types: :hashes)
    #
    # NOTE: When dealing with databases,
    # Redland (1.0.7) just crashes when the required tables aren't available!
    def self.initialize_storage(options = {})
      storage_type, storage_options = split_options(options)
      storage_type ||= :memory

      unless VALID_STORAGE_TYPES.include?(storage_type)
        raise RedlandError.new("Unknown storage type: #{storage_type}")
      end

      rdf_storage = Redland.librdf_new_storage(Redlander.rdf_world,
                                           storage_type.to_s,
                                           storage_options.delete(:name).to_s,
                                           Redlander.to_rdf_options(storage_options))
      raise RedlandError.new("Failed to initialize storage") unless rdf_storage
      ObjectSpace.define_finalizer(rdf_storage, proc { Redland.librdf_free_storage(rdf_storage) })

      rdf_storage
    end

    # Wrap changes to the given model in a transaction.
    # If an exception is raised in the block, the transaction is rolled back.
    # (Does not work for all storages, in which case the changes are instanteous).
    def self.transaction(model, &block)
      Redland.librdf_model_transaction_start(model.rdf_model).zero? || RedlandError.new("Failed to initialize a transaction")
      block.call
      Redland.librdf_model_transaction_commit(model.rdf_model).zero? || RedlandError.new("Failed to commit the transaction")
    rescue
      rollback(model)
    end

    # Rollback a latest transaction for the given model.
    def self.rollback(model)
      Redland.librdf_model_transaction_rollback(model.rdf_model).zero? || RedlandError.new("Failed to rollback the latest transaction")
    end


    private

    def self.split_options(options = {})
      storage_options = options.dup
      storage_type = storage_options.delete(:storage)
      [storage_type, storage_options]
    end

  end

end
