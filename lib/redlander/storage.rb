module Redlander
  class Storage
    VALID_STORAGE_TYPES = [:memory, :hashes, :file, :uri, :tstore, :mysql, :sqlite, :postgresql]

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
    def initialize(options = {})
      storage_type, storage_options = split_options(options.dup)

      unless VALID_STORAGE_TYPES.include?(storage_type)
        raise RedlandError.new("Unknown storage type: #{storage_type}")
      end

      @rdf_storage = Redland.librdf_new_storage(Redlander.rdf_world,
                                                storage_type.to_s,
                                                storage_options.delete(:name).to_s,
                                                Redlander.to_rdf_options(storage_options))
      raise RedlandError.new("Failed to initialize storage") if @rdf_storage.null?
      ObjectSpace.define_finalizer(self, proc { Redland.librdf_free_storage(@rdf_storage) })
    end


    private

    def split_options(options)
      storage_type = options.delete(:storage) || :memory
      [storage_type, options]
    end
  end
end
