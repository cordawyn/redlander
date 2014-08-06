module Redlander
  # RDF statement
  class Statement
    class << self
      private

      # @api private
      def finalize_statement(rdf_statement_ptr)
        proc { Redland.librdf_free_statement(rdf_statement_ptr) }
      end
    end

    # @api private
    def rdf_statement
      unless instance_variable_defined?(:@rdf_statement)
        @rdf_statement = case @source
                         when FFI::Pointer
                           @source
                         when Hash
                           # Create a new statement from nodes
                           s = rdf_node_from(@source[:subject])
                           p = rdf_node_from(@source[:predicate])
                           o = rdf_node_from(@source[:object])
                           Redland.librdf_new_statement_from_nodes(Redlander.rdf_world, s, p, o)
                         else
                           raise NotImplementedError, "Cannot create Statement from '#{@source.inspect}'"
                         end
        raise RedlandError, "Failed to create a new statement" if @rdf_statement.null?
        ObjectSpace.define_finalizer(self, self.class.send(:finalize_statement, @rdf_statement))
      end
      @rdf_statement
    end

    # Create an RDF statement.
    #
    # @param [Hash] source
    # @option source [Node, String, URI, nil] :subject
    # @option source [Node, String, URI, nil] :predicate
    # @option source [Node, String, URI, nil] :object
    # @raise [NotImplementedError] if cannot create a Statement from the given source.
    # @raise [RedlandError] if it fails to create a Statement.
    def initialize(source = {})
      # If FFI::Pointer is passed, wrap it instantly,
      # because it can be freed outside before it is used here.
      @source = source.is_a?(FFI::Pointer) ? wrap(source) : source
    end

    # Subject of the statment.
    #
    # @return [Node, nil]
    def subject
      if instance_variable_defined?(:@subject)
        @subject
      else
        rdf_node = Redland.librdf_statement_get_subject(rdf_statement)
        @subject = rdf_node.null? ? nil : Node.new(rdf_node)
      end
    end

    # Predicate of the statement.
    #
    # @return [Node, nil]
    def predicate
      if instance_variable_defined?(:@predicate)
        @predicate
      else
        rdf_node = Redland.librdf_statement_get_predicate(rdf_statement)
        @predicate = rdf_node.null? ? nil : Node.new(rdf_node)
      end
    end

    # Object of the statement.
    #
    # @return [Node, nil]
    def object
      if instance_variable_defined?(:@object)
        @object
      else
        rdf_node = Redland.librdf_statement_get_object(rdf_statement)
        @object = rdf_node.null? ? nil : Node.new(rdf_node)
      end
    end

    # Set the subject of the statement
    #
    # @param [Node, nil] node
    # @return [void]
    def subject=(node)
      Redland.librdf_statement_set_subject(rdf_statement, rdf_node_from(node))
      @subject = node
    end

    # Set the predicate of the statement
    #
    # @param [Node, nil] node
    # @return [void]
    def predicate=(node)
      Redland.librdf_statement_set_predicate(rdf_statement, rdf_node_from(node))
      @predicate = node
    end

    # Set the object of the statement
    #
    # @param [Node, nil] node
    # @return [void]
    def object=(node)
      Redland.librdf_statement_set_object(rdf_statement, rdf_node_from(node))
      @object = node
    end

    def eql?(other_statement)
      subject == other_statement.subject &&
        predicate == other_statement.predicate &&
        object == other_statement.object
    end
    alias_method :==, :eql?

    def hash
      self.class.hash + to_s.hash
    end

    def to_s
      Redland.librdf_statement_to_string(rdf_statement)
    end


    private

    # @api private
    def wrap(s)
      if s.null?
        raise RedlandError, "Failed to create a new statement"
      else
        Redland.librdf_new_statement_from_statement(s)
      end
    end

    # Create a Node from the source
    # and get its rdf_node, or return nil
    # @api private
    def rdf_node_from(source)
      case source
      when NilClass
        nil
      when Node
        Redland.librdf_new_node_from_node(source.rdf_node)
      else
        Redland.librdf_new_node_from_node(Node.new(source).rdf_node)
      end
    end
  end
end
