module ErrorContainer

  class Errors
    include Enumerable

    def initialize
      @container = []
    end

    def add(error_message)
      if @container.include?(error_message)
        @container
      else
        @container << error_message
      end
    end

    def each
      @container.each do |err|
        yield err
      end
    end

    def empty?
      @container.empty?
    end

    def clear
      @container.clear
    end

    def size
      @container.size
    end
  end

  def errors
    @errors ||= Errors.new
  end

end
