module Redlander
  class ParserProxy
    include StreamEnumerator

    def initialize(parser, content, options = {})
      # TODO: consider a streaming content, as it may be large to fit in memory
      @parser = parser
      @content = content
      @options = options
    end


    private

    def reset_stream
      @stream = Stream.new(@parser, @content, @options)
    end
  end
end
