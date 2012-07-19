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
        enum_for(:each)
      end
    end
  end
end
