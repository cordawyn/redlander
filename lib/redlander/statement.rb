module Redlander

  class Statement

    include ErrorContainer

    attr_reader :rdf_statement

    # Create an RDF statement.
    # Options are:
    #   :subject
    #   :predicate
    #   :object
    def initialize(options = {})
      @rdf_statement = if options.is_a?(FFI::Pointer)
                         # A special case, where you can pass an instance of SWIG::TYPE_p_librdf_statement_s
                         # in order to create a Statement from an internal RDF statement representation.
                         options
                       else
                         s = options[:subject] && Node.new(options[:subject]).rdf_node
                         p = options[:predicate] && Node.new(options[:predicate]).rdf_node
                         o = options[:object] && Node.new(options[:object]).rdf_node
                         Redland.librdf_new_statement_from_nodes(Redlander.rdf_world, s, p, o)
                       end

      raise RedlandError.new("Failed to create a new statement") if @rdf_statement.null?
      ObjectSpace.define_finalizer(@rdf_statement, proc { Redland.librdf_free_statement(@rdf_statement) })
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

    def model
      @model
    end

    # Add the statement to the given model.
    #
    # Returns the model on success, or nil.
    # NOTE: Duplicate statements are not added to the model.
    # However, this doesn't result in an error here.
    def model=(model)
      if model.nil?
        @model = nil
      else
        if self.valid?
          if Redland.librdf_model_add_statement(model.rdf_model, @rdf_statement).zero?
            @model = model
          else
            nil
          end
        end
      end
    end

    # Destroy the statement (remove it from the model, if possible).
    #
    # Returns true if successfully removed from the model, or false.
    # If the statement is not bound to a model, false is returned.
    def destroy
      if @model
        if Redland.librdf_model_remove_statement(@model.rdf_model, @rdf_statement).zero?
          self.model = nil
          true
        else
          false
        end
      else
        false
      end
    end

    def eql?(other_statement)
      model == other_statement.model &&
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
      if is_valid = attributes_satisfy?
        errors.clear
      else
        errors.add("is invalid")
      end
      is_valid
    end


    private

    def rdf_node_from(node)
      if node.nil?
        nil
      else
        # According to Redland docs,
        # the node here becomes a part of the statement
        # and must not be used by the caller!
        if node.frozen?
          raise RedlandError.new("The node is already bound to a statement and cannot be added.")
        else
          node.freeze.rdf_node
        end
      end
    end

    def attributes_satisfy?
      !subject.nil? && (subject.resource? || subject.blank?) &&
        !predicate.nil? && predicate.resource? &&
        !object.nil?
    end

  end

end
