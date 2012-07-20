module Redlander
  class Node
    attr_reader :rdf_node

    # Create a RDF node.
    # Argument can be:
    #   - an instance of URI - to create a RDF "resource",
    #   - an instance of Node - to create a copy of the node,
    #   - nil (or absent) - to create a "blank" node,
    #   - an instance of Statement ("role" must be supplied then) -
    #     to create a node from subject, predicate or object
    #     (determined by "role" parameter) of the statement.
    #   - any other Ruby object, which can be coerced into a literal.
    # If nothing else, a RedlandError is thrown.
    #
    # Note that you cannot create a resource node from an URI string,
    # it must be an instance of URI. Otherwise it is treated as a string literal.
    def initialize(arg = nil, role = :subject)
      @bound = false
      @rdf_node = case arg
                  when NilClass
                    Redland.librdf_new_node_from_blank_identifier(Redlander.rdf_world, nil)
                  when URI
                    Redland.librdf_new_node_from_uri_string(Redlander.rdf_world, arg.to_s)
                  when Node
                    Redland.librdf_new_node_from_node(arg.rdf_node)
                  when Statement
                    # TODO: Bound nodes should better be produced
                    # using an explicit "factory" like Node.from_statement
                    # to keep the clutter in the constructor at minimum.
                    # (Esp. handling the "bound" stuff)
                    @bound = true
                    case role
                    when :subject
                      Node._copy(Redland.librdf_statement_get_subject(arg.rdf_statement), @bound)
                    when :object
                      Node._copy(Redland.librdf_statement_get_object(arg.rdf_statement), @bound)
                    when :predicate
                      Node._copy(Redland.librdf_statement_get_predicate(arg.rdf_statement), @bound)
                    else
                      raise RedlandError.new("Invalid role specified")
                    end
                  else
                    value = arg.respond_to?(:xmlschema) ? arg.xmlschema : arg.to_s
                    datatype = Uri.new(XmlSchema.datatype_of(arg))
                    Redland.librdf_new_node_from_typed_literal(Redlander.rdf_world, value, nil, datatype.rdf_uri)
                  end
      if @rdf_node.null?
        raise RedlandError.new("Failed to create a new node") unless @bound
      else
        ObjectSpace.define_finalizer(self, proc { Redland.librdf_free_node(@rdf_node) })
        # bound nodes cannot be added to (other) statements
        freeze if @bound
      end
    end

    # Bound nodes are those belonging to a statement
    # (bound nodes cannot be modified or added to other statements).
    def bound?
      @bound
    end

    def resource?
      Redland.librdf_node_is_resource(@rdf_node) != 0
    end

    # Return true if node is a literal.
    def literal?
      Redland.librdf_node_is_literal(@rdf_node) != 0
    end

    # Return true if node is a blank node.
    def blank?
      Redland.librdf_node_is_blank(@rdf_node) != 0
    end

    # Return the datatype URI of the node.
    # Returns nil if the node is not a literal, or has no datatype URI.
    def datatype
      uri.to_s if literal?
    end

    # Equivalency. Only works for comparing two Nodes.
    def eql?(other_node)
      Redland.librdf_node_equals(@rdf_node, other_node.rdf_node) != 0
    end
    alias_method :==, :eql?

    def hash
      self.class.hash + to_s.hash
    end

    # Convert this node to a string (with a datatype suffix).
    def to_s
      Redland.librdf_node_to_string(@rdf_node)
    end

    # Internal URI of the Node
    def uri
      if resource?
        Uri.new(Redland.librdf_node_get_uri(@rdf_node))
      elsif literal?
        Uri.new(Redland.librdf_node_get_literal_value_datatype_uri(@rdf_node))
      else
        nil
      end
    end

    # Value of the literal node as a Ruby object instance.
    def value
      if resource?
        URI.parse(uri.to_s)
      else
        XmlSchema.instantiate(to_s)
      end
    end

    # :nodoc:
    def self._copy(n, bound = false)
      if n.null?
        if bound
          n
        else
          raise RedlandError.new("Failed to create a new node")
        end
      else
        Redland.librdf_new_node_from_node(n)
      end
    end
  end
end
