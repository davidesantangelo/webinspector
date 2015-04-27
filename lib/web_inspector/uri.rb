require 'addressable/uri'

module WebInspector
  class Uri
  	def initialize(url)
  		@url = url
  	end

  	def url
      normalized_uri
    end

    def host
      uri.host
    end

    def scheme
      uri.scheme
    end

    def port
      URI(normalized_uri).port
    end 

    private

    def uri
      Addressable::URI.parse(@url)
    end

    def normalized_uri
      uri.normalize.to_s
    end
  end
end