module RSS
  class XMLError < BaseError end

  module Validator
    def isRSS?(_url)
      File.extension("_url") == ".rss"
    end

    def isXML?(content)
    end
  end
end
