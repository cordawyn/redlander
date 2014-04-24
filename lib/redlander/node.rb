module Redlander
  # RDF node (usually, a part of an RDF statement)
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
                      @datatype = rdf_uri.null? ? XmlSchema.datatype_of("") : URI(Redland.librdf_uri_to_string(rdf_uri))
                    end
                    wrap(arg)
                  when NilClass
                    Redland.librdf_new_node_from_blank_identifier(Redlander.rdf_world, options[:blank_id])
                  when URI
                    Redland.librdf_new_node_from_uri_string(Redlander.rdf_world, arg.to_s)
                  else
                    @datatype = XmlSchema.datatype_of(arg)
                    value = arg.respond_to?(:xmlschema) ? arg.xmlschema : arg.to_s
                    lang = arg.respond_to?(:lang) ? arg.lang.to_s : nil
                    dt = lang ? nil : Uri.new(@datatype).rdf_uri
                    Redland.librdf_new_node_from_typed_literal(Redlander.rdf_world, value, lang, dt)
                  end
      raise RedlandError, "Failed to create a new node" if @rdf_node.null?
      ObjectSpace.define_finalizer(self, self.class.finalize(@rdf_node))
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
    # @return [URI, nil]
    def uri
      if resource?
        URI(to_s[1..-2])
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
        uri
      elsif blank?
        Redland.librdf_node_get_blank_identifier(@rdf_node).force_encoding("UTF-8")
      else
        v = Redland.librdf_node_get_literal_value(@rdf_node).force_encoding("UTF-8")
        v << "@#{lang}" if lang
        XmlSchema.instantiate(v, @datatype)
      end
    end

    def lang
      lng = Redland.librdf_node_get_literal_value_language(@rdf_node)
      lng ? lng.to_sym : nil
    end

    private

    # @api private
    def wrap(n)
      if n.null?
        raise RedlandError, "Failed to create a new node"
      else
        Redland.librdf_new_node_from_node(n)
      end
    end

    # @api private
    def self.finalize(rdf_node_ptr)
      proc {
        valid_ptr = Redlander.librdf_node_is_resource(rdf_node_ptr) or
          Redlander.librdf_node_is_literal(rdf_node_ptr) or
          Redlander.librdf_node_is_blank(rdf_node_ptr)
        Redland.librdf_free_node(rdf_node_ptr) if valid_ptr
      }
    end
  end
end
