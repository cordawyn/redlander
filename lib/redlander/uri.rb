module Redlander
  class Uri
    attr_reader :rdf_uri

    def initialize(source)
      @rdf_uri = case source
                 when URI, String
                   Redland.librdf_new_uri(Redlander.rdf_world, source.to_s)
                 when Node
                   if source.resource?
                     copy_rdf_uri_on_initialize(Redland.librdf_node_get_uri(source.rdf_node))
                   elsif source.literal?
                     copy_rdf_uri_on_initialize(Redland.librdf_node_get_literal_value_datatype_uri(source.rdf_node))
                   else
                     raise NotImplementedError.new
                   end
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


    private

    def copy_rdf_uri_on_initialize(u)
      if u.null?
        raise RedlandError.new("Failed to create URI")
      else
        Redland.librdf_new_uri_from_uri(u)
      end
    end
  end
end
