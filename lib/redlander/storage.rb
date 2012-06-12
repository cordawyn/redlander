module Redlander
  class Storage
    attr_reader :rdf_storage

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
    #   :virtuoso
    #   ... anything else that Redland can handle.
    #
    # Options are storage-specific.
    # Read the documentation for the appropriate Redland Storage module.
    #
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
    def initialize(options = {})
      storage_type, storage_options = split_options(options.dup)

      @rdf_storage = Redland.librdf_new_storage(Redlander.rdf_world,
                                                storage_type.to_s,
                                                storage_options.delete(:name).to_s,
                                                Redlander.to_rdf_options(storage_options))
      raise RedlandError.new("Failed to initialize '#{storage_type}' storage") if @rdf_storage.null?
      ObjectSpace.define_finalizer(self, proc { Redland.librdf_free_storage(@rdf_storage) })
    end


    private

    def split_options(options)
      storage_type = options.delete(:storage) || :memory
      [storage_type, options]
    end
  end
end
