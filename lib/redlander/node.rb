module Redlander
  class Node
    # @api private
    attr_reader :rdf_node

    # Datatype URI for the literal node, or nil
    attr_reader :datatype

    # Create a RDF node.
    #
    # @param [Any] arg
    #   - an instance of URI - to create a RDF "resource",
    #     Note that you cannot create a resource node from an URI string,
    #     it must be an instance of URI. Otherwise it is treated as a string literal.
    #   - nil (or absent) - to create a blank node,
    #   - any other Ruby object, which can be coerced into a literal.
    # @param [Hash] options
    # @option options [String] :blank_id optional ID to use for a blank node.
    # @raise [RedlandError] if it fails to create a node from the given args.
    def initialize(arg = nil, options = {})
      @rdf_node = case arg
                  when FFI::Pointer
                    unless Redland.librdf_node_is_literal(arg).zero?
                      rdf_uri = Redland.librdf_node_get_literal_value_datatype_uri(arg)
                      @datatype = rdf_uri.null? ? Uri.new(XmlSchema.datatype_of("")) : Uri.new(rdf_uri)
                    end
                    wrap(arg)
                  when NilClass
                    Redland.librdf_new_node_from_blank_identifier(Redlander.rdf_world, options[:blank_id])
                  when URI
                    Redland.librdf_new_node_from_uri_string(Redlander.rdf_world, arg.to_s)
                  else
                    value = arg.respond_to?(:xmlschema) ? arg.xmlschema : arg.to_s
                    @datatype = Uri.new(XmlSchema.datatype_of(arg))
                    Redland.librdf_new_node_from_typed_literal(Redlander.rdf_world, value, nil, @datatype.rdf_uri)
                  end
      raise RedlandError.new("Failed to create a new node") if @rdf_node.null?
      ObjectSpace.define_finalizer(self, proc { Redland.librdf_free_node(@rdf_node) })
    end

    # Check whether the node is a resource (identified by a URI)
    #
    # @return [Boolean]
    def resource?
      Redland.librdf_node_is_resource(@rdf_node) != 0
    end

    # Return true if node is a literal.
    #
    # @return [Boolean]
    def literal?
      Redland.librdf_node_is_literal(@rdf_node) != 0
    end

    # Return true if node is a blank node.
    #
    # @return [Boolean]
    def blank?
      Redland.librdf_node_is_blank(@rdf_node) != 0
    end

    # Equivalency. Only works for comparing two Nodes.
    #
    # @param [Node] other_node Node to be compared with.
    # @return [Boolean]
    def eql?(other_node)
      Redland.librdf_node_equals(@rdf_node, other_node.rdf_node) != 0
    end
    alias_method :==, :eql?

    def hash
      self.class.hash + to_s.hash
    end

    # Convert this node to a string (with a datatype suffix).
    #
    # @return [String]
    def to_s
      Redland.librdf_node_to_string(@rdf_node)
    end

    # Internal URI of the Node.
    #
    # Returns the datatype URI for literal nodes,
    # nil for blank nodes.
    #
    # @return [Uri, nil]
    def uri
      if resource?
        Uri.new(Redland.librdf_node_get_uri(@rdf_node))
      elsif literal?
        datatype
      else
        nil
      end
    end

    # Value of the literal node as a Ruby object instance.
    #
    # Returns an instance of URI for resource nodes,
    # "blank identifier" for blank nodes.
    #
    # @return [URI, Any]
    def value
      if resource?
        URI.parse(uri.to_s)
      else
        XmlSchema.instantiate(to_s)
      end
    end


    private

    # @api private
    def wrap(n)
      if n.null?
        raise RedlandError.new("Failed to create a new node")
      else
        Redland.librdf_new_node_from_node(n)
      end
    end
  end
end
