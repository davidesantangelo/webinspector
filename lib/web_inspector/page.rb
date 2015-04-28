require 'nokogiri'
require 'uri'
require 'open-uri'
require 'open_uri_redirections'
require 'faraday'

require File.expand_path(File.join(File.dirname(__FILE__), 'inspector'))
require File.expand_path(File.join(File.dirname(__FILE__), 'request'))

module WebInspector
  class Page
  	attr_reader :url, :scheme, :host, :port, :title, :description, :meta, :links, :images, :response

    def initialize(url, options = {})
      @url = url
      @options = options
      @request = WebInspector::Request.new(url)
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

    def meta
      @inspector.meta
    end

    def url
      @request.url
    end

    def host
      @request.host
    end

    def scheme
      @request.scheme
    end

    def port
      @request.port
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
        'images'				=> images,
        'response'      => { 'status'  => response.status,
                             'headers' => response.headers }
      }
    end

    def response
      @response ||= fetch
    rescue Faraday::TimeoutError, Faraday::Error::ConnectionFailed, RuntimeError, URI::InvalidURIError => e
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

    def with_default_scheme(request)
      request.url && request.scheme.nil? ? 'http://' + request.url : request.url
    end

    def default_user_agent
      "WebInspector/#{WebInspector::VERSION} (+https://github.com/davidesantangelo/webinspector)"
    end

    def page
      Nokogiri::HTML(open(with_default_scheme(@request), :allow_redirections => :safe))
    end
  end
end