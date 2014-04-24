require 'redlander/parsing'
require 'redlander/serializing'
require 'redlander/model_proxy'
require "redlander/query/results"

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
    # @option options [String] :hash_type hash type (for store types: :bdb), can be either 'memory' or 'bdb',
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

      @rdf_model = Redland.librdf_new_model(Redlander.rdf_world, @rdf_storage, "")
      raise RedlandError, "Failed to create a new model" if @rdf_model.null?

      ObjectSpace.define_finalizer(self, self.class.finalize(@rdf_storage, @rdf_model))
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

    # Size of the model, in statements.
    #
    # @return [Fixnum]
    def size
      s = Redland.librdf_model_size(@rdf_model)
      s < 0 ? statements.count : s
    end

    # Query the model RDF graph using a query language
    #
    # @param [String] q the text of the query
    # @param [Hash<Symbol => [String, URI]>] options options for the query
    # @option options [String] :language language of the query, one of:
    #   - "sparql10" SPARQL 1.0 W3C RDF Query Language (default)
    #   - "sparql" SPARQL 1.1 (DRAFT) Query and Update Languages
    #   - "sparql11-query" SPARQL 1.1 (DRAFT) Query Language
    #   - "sparql11-update" SPARQL 1.1 (DRAFT) Update Language
    #   - "laqrs" LAQRS adds to Querying RDF in SPARQL
    #   - "rdql" RDF Data Query Language (RDQL)
    # @option options [String] :language_uri URI of the query language, if applicable
    # @option options [String] :base_uri base URI of the query, if applicable
    # @return [void]
    # @note
    #   The returned value is determined by the type of the query:
    #   - [Boolean] for SPARQL ASK queries (ignores block, if given)
    #   - [Redlander::Model] for SPARQL CONSTRUCT queries
    #     if given a block, yields the constructed statements to it instead
    #   - [Array<Hash>] for SPARQL SELECT queries
    #     where hash values are Redlander::Node instances;
    #     if given a block, yields each binding hash to it
    #   - nil, if query fails
    # @raise [RedlandError] if fails to create a query
    def query(q, options = {}, &block)
      query = Query::Results.new(q, options)
      query.process(self, &block)
    end

    # Merge statements from another model
    # (duplicates and invalid statements are skipped)
    #
    # @param [Redlander::Model] model
    # @return [self]
    def merge(model)
      rdf_stream = Redland.librdf_model_as_stream(model.rdf_model)
      raise RedlandError, "Failed to convert model to a stream" if rdf_stream.null?

      begin
        Redland.librdf_model_add_statements(@rdf_model, rdf_stream)
        self
      ensure
        Redland.librdf_free_stream(rdf_stream)
      end
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
        result = yield
        transaction_commit
        result
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

    private

    # @api private
    def self.finalize(rdf_storage_ptr, rdf_model_ptr)
      proc {
        Redland.librdf_free_storage(rdf_storage_ptr)
        Redland.librdf_free_model(rdf_model_ptr)
      }
    end
  end
end
