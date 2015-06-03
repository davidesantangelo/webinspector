require 'nokogiri'
require 'uri'
require 'open-uri'
require 'open_uri_redirections'
require 'faraday'

require File.expand_path(File.join(File.dirname(__FILE__), 'inspector'))
require File.expand_path(File.join(File.dirname(__FILE__), 'request'))
require File.expand_path(File.join(File.dirname(__FILE__), 'blog'))

module WebInspector
  class Page
    attr_reader :url, :scheme, :host, :port, :title, :description, :body, :meta, :links, :images, :response

    def initialize(url, options = {})
      @url = url
      @options = options
      @request = WebInspector::Request.new(url)
      @inspector = WebInspector::Inspector.new(page)
      @blog = WebInspector::Blog.new(page)
    end

    def title
      @inspector.title
    end

    def description
      @inspector.description
    end

    def body
      @inspector.body
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

    # added methods
    # returns the content of the first blog post on the page.
    def first_blog_post_content
      @blog.first_blog_post_content
    end

    # array of all posts on the page.
    def all_posts
      if @blog.all_posts
        return_array = []
        @blog.all_posts.each do |post|
          return_array << { title: post.css('h2').empty? ? post.css('h1').text : post.css('h2').text,
                            content: post.css('p').text }
        end
        return_array
      else
        []
      end
    end
    # end added methods

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
      Nokogiri::HTML(open(with_default_scheme(@request), allow_redirections: :safe))
    end
  end
end