module Redlander
  class Statement
    attr_reader :rdf_statement

    # Create an RDF statement.
    # Source can be:
    #   Hash, where
    #     :subject
    #     :predicate
    #     :object
    def initialize(source = {})
      @rdf_statement = case source
                       when FFI::Pointer
                         wrap(source)
                       when Hash
                         # Create a new statement from nodes
                         s = rdf_node_from(source[:subject])
                         p = rdf_node_from(source[:predicate])
                         o = rdf_node_from(source[:object])
                         Redland.librdf_new_statement_from_nodes(Redlander.rdf_world, s, p, o)
                       else
                         # TODO
                         raise NotImplementedError.new
                       end
      raise RedlandError.new("Failed to create a new statement") if @rdf_statement.null?
      ObjectSpace.define_finalizer(self, proc { Redland.librdf_free_statement(@rdf_statement) })
    end

    def subject
      rdf_node = Redland.librdf_statement_get_subject(@rdf_statement)
      rdf_node.null? ? nil : Node.new(rdf_node)
    end

    def predicate
      rdf_node = Redland.librdf_statement_get_predicate(@rdf_statement)
      rdf_node.null? ? nil : Node.new(rdf_node)
    end

    def object
      rdf_node = Redland.librdf_statement_get_object(@rdf_statement)
      rdf_node.null? ? nil : Node.new(rdf_node)
    end

    # set the subject of the statement
    def subject=(node)
      Redland.librdf_statement_set_subject(@rdf_statement, rdf_node_from(node))
    end

    # set the predicate of the statement
    def predicate=(node)
      Redland.librdf_statement_set_predicate(@rdf_statement, rdf_node_from(node))
    end

    # set the object of the statement
    def object=(node)
      Redland.librdf_statement_set_object(@rdf_statement, rdf_node_from(node))
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
      Redland.librdf_statement_to_string(@rdf_statement)
    end


    private

    # :nodoc:
    def wrap(s)
      if s.null?
        raise RedlandError.new("Failed to create a new statement")
      else
        Redland.librdf_new_statement_from_statement(s)
      end
    end

    # Create a Node from the source
    # and get its rdf_node, or return nil
    def rdf_node_from(source)
      case source
      when NilClass
        nil
      when Node
        source.rdf_node
      else
        Node.new(source).rdf_node
      end
    end
  end
end
