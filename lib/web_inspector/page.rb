require 'nokogiri'
require 'uri'
require 'addressable/uri'
require 'open-uri'
require 'open_uri_redirections'

require File.expand_path(File.join(File.dirname(__FILE__), 'inspector'))

module WebInspector
  class Page
  	attr_reader :url, :scheme, :host, :port, :title, :description, :meta, :links, :images, :size, :response

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

    def links
      @inspector.links
    end

    def images
      @inspector.images
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

    def to_hash
      {
        'url'           => url,
        'scheme'        => scheme,
        'host'          => host,
        'port'          => port,
        'title'         => title,
        'description'  	=> description,
        'meta'  				=> meta,
        'links'					=> links,
        'images'				=> images
        'response'      => { 'status'  => response.status,
                             'headers' => response.headers }
      }
    end

    def response
      @response ||= fetch
    rescue Faraday::TimeoutError, Faraday::Error::ConnectionFailed, RuntimeError, URI::InvalidURIError => e
      @exception_log << e
      nil
    end

    private
    
    def fetch
      session = Faraday.new(:url => url) do |faraday|
        faraday.request :retry, max: @retries

        if @allow_redirections
          faraday.use FaradayMiddleware::FollowRedirects, limit: 10
          faraday.use :cookie_jar
        end

        faraday.headers.merge!(@headers || {})
        faraday.adapter :net_http
      end

      response = session.get do |req|
        req.options.timeout      = @connection_timeout
        req.options.open_timeout = @read_timeout
      end

      @url.url = response.env.url.to_s

      response
    end

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