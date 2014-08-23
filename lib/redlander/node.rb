module Redlander
  # RDF node (usually, a part of an RDF statement)
  class Node
    class << self
      private

      # @api private
      def finalize_node(rdf_node_ptr)
        proc { Redland.librdf_free_node(rdf_node_ptr) }
      end
    end

    # @api private
    def rdf_node
      unless instance_variable_defined?(:@rdf_node)
        @rdf_node = case @arg
                    when FFI::Pointer
                      @arg
                    when NilClass
                      Redland.librdf_new_node_from_blank_identifier(Redlander.rdf_world, @options[:blank_id])
                    when URI
                      Redland.librdf_new_node_from_uri_string(Redlander.rdf_world, @arg.to_s)
                    else
                      if @options[:resource]
                        Redland.librdf_new_node_from_uri_string(Redlander.rdf_world, @arg.to_s)
                      else
                        value = @arg.respond_to?(:xmlschema) ? @arg.xmlschema : @arg.to_s
                        lang = @arg.respond_to?(:lang) ? @arg.lang.to_s : nil
                        dt = lang ? nil : Uri.new(XmlSchema.datatype_of(@arg)).rdf_uri
                        Redland.librdf_new_node_from_typed_literal(Redlander.rdf_world, value, lang, dt)
                      end
                    end
        raise RedlandError, "Failed to create a new node" if @rdf_node.null?
        ObjectSpace.define_finalizer(self, self.class.send(:finalize_node, @rdf_node))
      end
      @rdf_node
    end

    # Datatype URI for the literal node, or nil
    def datatype
      if instance_variable_defined?(:@datatype)
        @datatype
      else
        @datatype = if literal?
                      rdf_uri = Redland.librdf_node_get_literal_value_datatype_uri(rdf_node)
                      rdf_uri.null? ? XmlSchema.datatype_of("") : URI.parse(Redland.librdf_uri_to_string(rdf_uri))
                    else
                      nil
                    end
      end
    end

    # Create a RDF node.
    #
    # @param [Any] arg
    #   - an instance of URI - to create an RDF "resource",
    #     see also :resource option below.
    #   - nil (or absent) - to create a blank node,
    #   - any other Ruby object, which can be coerced into a literal.
    # @param [Hash] options
    # @option options [String] :blank_id optional ID to use for a blank node.
    # @option options [Boolean] :resource interpret arg as URI string and create an RDF "resource".
    # @raise [RedlandError] if it fails to create a node from the given args.
    def initialize(arg = nil, options = {})
      # If FFI::Pointer is passed, wrap it instantly,
      # because it can be freed outside before it is used here.
      @arg = arg.is_a?(FFI::Pointer) ? wrap(arg) : arg
      @options = options
    end

    # Check whether the node is a resource (identified by a URI)
    #
    # @return [Boolean]
    def resource?
      Redland.librdf_node_is_resource(rdf_node) != 0
    end

    # Return true if node is a literal.
    #
    # @return [Boolean]
    def literal?
      Redland.librdf_node_is_literal(rdf_node) != 0
    end

    # Return true if node is a blank node.
    #
    # @return [Boolean]
    def blank?
      Redland.librdf_node_is_blank(rdf_node) != 0
    end

    # Equivalency. Only works for comparing two Nodes.
    #
    # @param [Node] other_node Node to be compared with.
    # @return [Boolean]
    def eql?(other_node)
      Redland.librdf_node_equals(rdf_node, other_node.rdf_node) != 0
    end
    alias_method :==, :eql?

    def hash
      self.class.hash + to_s.hash
    end

    # Convert this node to a string (with a datatype suffix).
    #
    # @return [String]
    def to_s
      Redland.librdf_node_to_string(rdf_node)
    end

    # Internal URI of the Node.
    #
    # Returns the datatype URI for literal nodes,
    # nil for blank nodes.
    #
    # @return [URI, nil]
    def uri
      if resource?
        URI.parse(to_s[1..-2])
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
        Redland.librdf_node_get_blank_identifier(rdf_node).force_encoding("UTF-8")
      else
        v = Redland.librdf_node_get_literal_value(rdf_node).force_encoding("UTF-8")
        v << "@#{lang}" if lang
        XmlSchema.instantiate(v, datatype)
      end
    end

    def lang
      lng = Redland.librdf_node_get_literal_value_language(rdf_node)
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
  end
end
