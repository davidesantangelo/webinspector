require 'nokogiri'
require 'uri'
require 'addressable/uri'
require 'open-uri'
require 'open_uri_redirections'

require File.expand_path(File.join(File.dirname(__FILE__), 'inspector'))

module WebInspector
  class Page
  	attr_reader :url, :scheme, :host, :title, :description, :meta, :links, :images, :size, :response

    def initialize(url, options = {})
      @url = url
      @options = options
      @inspector = WebInspector::Inspector.new(page)
    end

    def title
      @inspector.title
    end

    def description
      @inspector.description
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
    
    def to_hash
      {
        'url'           => url,
        'scheme'        => scheme,
        'host'          => host,
        'title'         => title,
        'description'  	=> description,
        'meta'  				=> meta,
        'links'					=> links,
        'images'				=> images,
        'size'          => size,
        'response'      => { 'status'  => response.status,
                             'headers' => response.headers }
      }
    end

    private
    
    def uri
      Addressable::URI.parse(@url)
    end

    def normalized_uri
      uri.normalize.to_s
    end

    def default_user_agent
      "WebInspector/#{WebInspector::VERSION} (+https://github.com/davidesantangelo/webinspector)"
    end
    
    def page
      Nokogiri::HTML(open(normalized_uri, :allow_redirections => :safe))
    end
  end
end