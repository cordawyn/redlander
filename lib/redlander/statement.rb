require 'redlander/stream'
require "redlander/error_container"

module Redlander
  class Statement
    include ErrorContainer

    attr_reader :rdf_statement

    # Create an RDF statement.
    # Source can be:
    #   Hash, where
    #     :subject
    #     :predicate
    #     :object
    #   Stream, so that a statement is extracted from its current position
    def initialize(source = {})
      @rdf_statement = case source
                       when FFI::Pointer
                         wrap(source)
                       when Stream
                         # Pull a (current) statement from the stream
                         wrap(Redland.librdf_stream_get_object(source.rdf_stream))
                       when Hash
                         # Create a new statement from nodes
                         s = source[:subject] && Node.new(source[:subject]).rdf_node
                         p = source[:predicate] && Node.new(source[:predicate]).rdf_node
                         o = source[:object] && Node.new(source[:object]).rdf_node
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
      binding_to_statement(node) {
        Redland.librdf_statement_set_subject(@rdf_statement, node.rdf_node)
      }
    end

    # set the predicate of the statement
    def predicate=(node)
      binding_to_statement(node) {
        Redland.librdf_statement_set_predicate(@rdf_statement, node.rdf_node)
      }
    end

    # set the object of the statement
    def object=(node)
      binding_to_statement(node) {
        Redland.librdf_statement_set_object(@rdf_statement, node.rdf_node)
      }
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

    # A valid statement satisfies the following:
    # URI or blank subject, URI predicate and URI or blank or literal object (i.e. anything).
    def valid?
      attributes_satisfy? ? errors.clear : errors.add("is invalid")
      errors.empty?
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

    def attributes_satisfy?
      !subject.nil? && (subject.resource? || subject.blank?) &&
        !predicate.nil? && predicate.resource? &&
        !object.nil?
    end

    def binding_to_statement(node)
      if node.frozen?
        raise RedlandError.new("Cannot assign a bound node")
      else
        node.freeze
        yield
      end
    end
  end
end
