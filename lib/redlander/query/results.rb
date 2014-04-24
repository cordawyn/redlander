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

        ObjectSpace.define_finalizer(self, self.class.finalize(@rdf_query))
      end

      def process(model)
        @rdf_results = Redland.librdf_model_query_execute(model.rdf_model, @rdf_query)

        begin
          case
          when bindings?
            if block_given?
              return nil if @rdf_results.null?
              each { yield process_bindings }
            else
              return [] if @rdf_results.null?
              map { process_bindings }
            end
          when boolean?
            return nil if @rdf_results.null?
            process_boolean
          when graph?
            return nil if @rdf_results.null?
            if block_given?
              process_graph { |statement| yield statement }
            else
              process_graph
            end
          when syntax?
            process_syntax
          else
            raise RedlandError, "Cannot determine the type of query results"
          end
        ensure
          Redland.librdf_free_query_results(@rdf_results)
        end
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
            unless value.null?
              bindings[name] = Node.new(value)
              Redland.librdf_free_node(value)
            end
            n -= 1
          end
        end
      end

      def process_boolean
        value = Redland.librdf_query_results_get_boolean(@rdf_results)
        return value >= 0 ? !value.zero? : nil
      end

      def process_graph
        rdf_stream = Redland.librdf_query_results_as_stream(@rdf_results)
        if block_given?
          while Redland.librdf_stream_end(rdf_stream).zero?
            statement = Statement.new(Redland.librdf_stream_get_object(rdf_stream))
            yield statement
            Redland.librdf_stream_next(rdf_stream)
          end
        else
          Model.new.tap do |model|
            Redland.librdf_model_add_statements(model.rdf_model, rdf_stream)
          end
        end
      ensure
        Redland.librdf_free_stream(rdf_stream)
      end

      def process_syntax
        raise NotImplementedError, "Don't know how to handle syntax type results"
      end

      # @api private
      def self.finalize(rdf_query_ptr)
        proc {
          Redland.librdf_free_query(rdf_query_ptr)
        }
      end
    end
  end
end
