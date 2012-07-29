module Redlander
  module Query
    # @api private
    class Results
      include Enumerable

      # (see Model#query)
      def initialize(q, options = {})
        language = options[:language] || "sparql10"
        language_uri = options[:language_uri] && options[:language_uri].to_s
        base_uri = options[:base_uri] && options[:base_uri].to_s

        @rdf_query = Redland.librdf_new_query(Redlander.rdf_world, language, language_uri, q, base_uri)
        raise RedlandError, "Failed to create a #{language.upcase} query from '#{q}'" if @rdf_query.null?

        ObjectSpace.define_finalizer(self, proc { Redland.librdf_free_query(@rdf_query) })
      end

      def process(model)
        @rdf_results = Redland.librdf_model_query_execute(model.rdf_model, @rdf_query)

        if @rdf_results.null?
          return nil
        else
          case
          when bindings?
            if block_given?
              each { yield process_bindings }
            else
              map { process_bindings }
            end
          when boolean?
            if block_given?
              yield process_boolean
            else
              process_boolean
            end
          when graph?
            if block_given?
              yield process_graph
            else
              process_graph
            end
          when syntax?
            process_syntax
          else
            raise RedlandError, "Cannot determine the type of query results"
          end
        end
      ensure
        Redland.librdf_free_query_results(@rdf_results)
      end

      def each
        if block_given?
          while Redland.librdf_query_results_finished(@rdf_results).zero?
            yield self
            Redland.librdf_query_results_next(@rdf_results)
          end
        else
          enum_for(:each)
        end
      end

      def bindings?
        !Redland.librdf_query_results_is_bindings(@rdf_results).zero?
      end

      def boolean?
        !Redland.librdf_query_results_is_boolean(@rdf_results).zero?
      end

      def graph?
        !Redland.librdf_query_results_is_graph(@rdf_results).zero?
      end

      def syntax?
        !Redland.librdf_query_results_is_syntax(@rdf_results).zero?
      end

      private

      def process_bindings
        {}.tap do |bindings|
          n = Redland.librdf_query_results_get_bindings_count(@rdf_results)
          while n > 0
            name = Redland.librdf_query_results_get_binding_name(@rdf_results, n-1)
            value = Redland.librdf_query_results_get_binding_value(@rdf_results, n-1)
            bindings[name] = Node.new(value) unless value.null?
            n -= 1
          end
        end
      end

      def process_boolean
        value = Redland.librdf_query_results_get_boolean(@rdf_results)
        return value >= 0 ? !value.zero? : nil
      end

      def process_graph
        raise NotImplementedError
      end

      def process_syntax
        raise NotImplementedError, "Don't know how to handle syntax type results"
      end
    end
  end
end
