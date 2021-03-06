module Redlander
  # @api private
  # Uri (for internal use)
  class Uri
    # @api private
    def rdf_uri
      unless instance_variable_defined?(:@rdf_uri)
        @rdf_uri = case @source
                   when FFI::Pointer
                     @source
                   when URI, String
                     Redland.librdf_new_uri(Redlander.rdf_world, @source.to_s)
                   else
                     raise NotImplementedError, "Cannot create Uri from '#{@source.inspect}'"
                   end
        raise RedlandError, "Failed to create Uri from '#{@source.inspect}'" if @rdf_uri.null?
        ObjectSpace.define_finalizer(self, self.class.send(:finalize_uri, @rdf_uri))
      end
      @rdf_uri
    end

    class << self
      private

      # @api private
      def finalize_uri(rdf_uri_ptr)
        proc { Redland.librdf_free_uri(rdf_uri_ptr) }
      end
    end

    # Create Redlander::Uri
    #
    # @param [URI, String] source String or URI object to wrap into Uri.
    # @raise [NotImplementedError] if cannot create a Uri from the given source.
    # @raise [RedlandError] if it fails to create a Uri.
    def initialize(source)
      @source = source.is_a?(FFI::Pointer) ? wrap(source) : source
    end

    def to_s
      Redland.librdf_uri_to_string(rdf_uri)
    end

    def eql?(other_uri)
      other_uri.is_a?(Uri) && (Redland.librdf_uri_equals(rdf_uri, other_uri.rdf_uri) != 0)
    end
    alias_method :==, :eql?


    private

    # @api private
    def wrap(u)
      if u.null?
        raise RedlandError, "Failed to create Uri"
      else
        Redland.librdf_new_uri_from_uri(u)
      end
    end
  end
end
