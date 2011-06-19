module Redlander
  class Uri
    attr_reader :rdf_uri

    def initialize(uri)
      uri = uri.is_a?(URI) ? uri.to_s : uri
      @rdf_uri = Redland.librdf_new_uri(Redlander.rdf_world, uri)
      raise RedlandError.new("Failed to create URI from '#{uri}'") if @rdf_uri.null?
      ObjectSpace.define_finalizer(self, proc { Redland.librdf_free_uri(@rdf_uri) })
      @rdf_uri
    end
  end
end
