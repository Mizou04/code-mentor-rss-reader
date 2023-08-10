module RSS 
  class BasicView
    def prompt
      raise "NOT IMPLEMENTED"
    end
    def render
      raise "NOT IMPLEMENTED"
    end
  end

  class Terminal < BasicView
    attr_reader :urls :results

    def initialize
      @urls ||= []
      @results ||= []
    end

    def prompt(_question="")
      if _question == ""
        _question << "Enter a valid RSS URL\n"
      end
      STDOUT << _question << "\n"
    end
    
    def render
      if(results.empty?)
        STDOUT << "NO RESULT"
        exit
      @results.each_with_index do |res, i|
        STDOUT << "#{i}\t-" << res
      end
      flush
    end

    def get(_url)
      @urls << _url.split " "
    end

    private:

      def flush
        @urls = []
        @results = []
      end


  end

end
