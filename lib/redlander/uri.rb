module Redlander
  class Uri
    attr_reader :rdf_uri

    def initialize(source)
      @rdf_uri = case source
                 when FFI::Pointer
                   Uri._copy(source)
                 when URI, String
                   Redland.librdf_new_uri(Redlander.rdf_world, source.to_s)
                 else
                   # TODO
                   raise NotImplementedError.new
                 end
      raise RedlandError.new("Failed to create URI from '#{source.inspect}'") if @rdf_uri.null?
      ObjectSpace.define_finalizer(self, proc { Redland.librdf_free_uri(@rdf_uri) })
    end

    def to_s
      Redland.librdf_uri_to_string(@rdf_uri)
    end

    # :nodoc:
    def self._copy(u)
      if u.null?
        raise RedlandError.new("Failed to create URI")
      else
        Redland.librdf_new_uri_from_uri(u)
      end
    end
  end
end
