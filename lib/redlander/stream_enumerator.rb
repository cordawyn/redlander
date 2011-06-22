module Redlander
  module StreamEnumerator
    include Enumerable

    def each
      if block_given?
        reset_stream
        while !@stream.eos?
          yield @stream.current
          @stream.succ
        end
      else
        raise ::LocalJumpError.new("no block given")
      end
    end
  end
end
