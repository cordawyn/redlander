module Redlander

  class Node

    attr_reader :rdf_node

    # Create a RDF node.
    # Argument can be:
    #   - an instance of URI - to create a RDF "resource",
    #   - an instance of Node - to create a copy of the node,
    #   - nil (or absent) - to create a "blank" node,
    #   - any other Ruby object, which can be coerced into a literal.
    # If nothing else, a RedlandError is thrown.
    #
    # Note, that you cannot create a resource node from an URI string,
    # it must be an instance of URI. Otherwise it is treated as a string literal.
    def initialize(arg = nil)
      @rdf_node = if arg.nil?
                    Redland.librdf_new_node_from_blank_identifier(Redlander.rdf_world, nil)
                  elsif arg.is_a?(URI)
                    Redland.librdf_new_node_from_uri_string(Redlander.rdf_world, arg.to_s)
                  elsif arg.is_a?(FFI::Pointer)
                    # A special case, where you can pass an instance of SWIG::TYPE_p_librdf_node_s
                    # in order to create a Node from an internal RDF node representation.
                    arg
                  elsif arg.is_a?(Node)
                    Redland.librdf_new_node_from_node(arg.rdf_node)
                  else
                    value = arg.respond_to?(:xmlschema) ? arg.xmlschema : arg.to_s
                    datatype = Redlander.to_rdf_uri(XmlSchema.datatype_of(arg))
                    Redland.librdf_new_node_from_typed_literal(Redlander.rdf_world, value, nil, datatype)
                  end

      raise RedlandError.new("Failed to create a new node") if @rdf_node.null?
      ObjectSpace.define_finalizer(@rdf_node, proc { Redland.librdf_free_node(@rdf_node) })
    end

    def resource?
      !Redland.librdf_node_is_resource(@rdf_node).zero?
    end

    # Return true if node is a literal.
    def literal?
      !Redland.librdf_node_is_literal(@rdf_node).zero?
    end

    # Return true if node is a blank node.
    def blank?
      !Redland.librdf_node_is_blank(@rdf_node).zero?
    end

    # Return the datatype URI of the node.
    # Returns nil if the node is not a literal, or has no datatype URI.
    def datatype
      rdf_uri = Redland.librdf_node_get_literal_value_datatype_uri(@rdf_node)
      unless rdf_uri.null?
        ObjectSpace.define_finalizer(rdf_uri, proc { Redland.librdf_free_uri(rdf_uri) })
        Redland.librdf_uri_to_string(rdf_uri)
      end
    end

    # Equivalency. Only works for comparing two Nodes.
    def eql?(other_node)
      !Redland.librdf_node_equals(@rdf_node, other_node.rdf_node).zero?
    end
    alias_method :==, :eql?

    def hash
      self.class.hash + to_s.hash
    end

    # Convert this node to a string (with a datatype suffix).
    def to_s
      Redland.librdf_node_to_string(@rdf_node)
    end

    # Value of the literal node as a Ruby object instance.
    def value
      if resource?
        rdf_uri = Redland.librdf_node_get_uri(@rdf_node)
        unless rdf_uri.null?
          ObjectSpace.define_finalizer(rdf_uri, proc { Redland.librdf_free_uri(rdf_uri) })
          URI.parse(Redland.librdf_uri_to_string(rdf_uri))
        end
      else
        XmlSchema.instantiate(to_s)
      end
    end

  end

end
