# frozen_string_literal: true

require 'nokogiri'
require 'uri'
require 'open-uri'
require 'open_uri_redirections'
require 'faraday'
require 'public_suffix'

# Explicitly load Faraday::Retry if available
begin
  require 'faraday/retry'
rescue LoadError
  # Faraday retry is not available
end

require File.expand_path(File.join(File.dirname(__FILE__), 'inspector'))
require File.expand_path(File.join(File.dirname(__FILE__), 'request'))

module WebInspector
  class Page
    attr_reader :url, :scheme, :host, :port, :title, :description, :body, :meta, :links,
                :domain_links, :domain_images, :images, :response, :status_code, :favicon

    DEFAULT_TIMEOUT = 30
    DEFAULT_RETRIES = 3
    DEFAULT_USER_AGENT = -> { "WebInspector/#{WebInspector::VERSION} (+https://github.com/davidesantangelo/webinspector)" }

    # Initialize a new WebInspector Page
    #
    # @param url [String] The URL to inspect
    # @param options [Hash] Optional parameters
    # @option options [Integer] :timeout Request timeout in seconds
    # @option options [Integer] :retries Number of retries for failed requests
    # @option options [Hash] :headers Custom HTTP headers
    # @option options [Boolean] :allow_redirections Whether to follow redirects
    # @option options [String] :user_agent Custom user agent
    def initialize(url, options = {})
      @url = url
      @options = options
      @retries = options[:retries] || DEFAULT_RETRIES
      @timeout = options[:timeout] || DEFAULT_TIMEOUT
      @headers = options[:headers] || { 'User-Agent' => options[:user_agent] || DEFAULT_USER_AGENT.call }
      @allow_redirections = options[:allow_redirections].nil? || options[:allow_redirections]

      @request = WebInspector::Request.new(url)

      begin
        @inspector = WebInspector::Inspector.new(page)
        @inspector.set_url(url, host)
        @status_code = 200
      rescue StandardError => e
        @error = e
        @status_code = e.respond_to?(:status_code) ? e.status_code : 500
      end
    end

    # Check if the page was successfully loaded
    #
    # @return [Boolean] true if the page was loaded, false otherwise
    def success?
      !@inspector.nil? && !@error
    end

    # Get the error message if any
    #
    # @return [String, nil] The error message or nil if no error
    def error_message
      @error&.message
    end

    # Delegate methods to inspector
    %i[title description body links images meta].each do |method|
      define_method(method) do
        return nil unless success?

        @inspector.send(method)
      end
    end

    # Special case for find method that takes arguments
    def find(words)
      return nil unless success?

      @inspector.find(words)
    end

    # Delegate methods to request
    %i[url host domain scheme port].each do |method|
      define_method(method) do
        @request.send(method)
      end
    end

    # Get the favicon URL if available
    #
    # @return [String, nil] The favicon URL or nil if not found
    def favicon
      return @favicon if defined?(@favicon)

      return nil unless success?

      @favicon = begin
        # Try multiple approaches to find favicon

        # 1. Look for standard favicon link tags
        favicon_link = @inspector.page.css("link[rel='shortcut icon'], link[rel='icon'], link[rel='apple-touch-icon']").first
        if favicon_link && favicon_link['href']
          begin
            return URI.join(url, favicon_link['href']).to_s
          rescue URI::InvalidURIError
            # Try next method
          end
        end

        # 2. Try the default location /favicon.ico
        "#{scheme}://#{host}/favicon.ico"
      rescue StandardError
        nil
      end
    end

    def domain_links(u = domain)
      return [] unless success?

      @inspector.domain_links(u, host)
    end

    def domain_images(u = domain)
      return [] unless success?

      @inspector.domain_images(u, host)
    end

    # Get full JSON representation of the page
    #
    # @return [Hash] JSON representation of the page
    def to_hash
      {
        'url' => url,
        'scheme' => scheme,
        'host' => host,
        'port' => port,
        'title' => title,
        'description' => description,
        'meta' => meta,
        'links' => links,
        'images' => images,
        'favicon' => favicon,
        'response' => {
          'status' => status_code,
          'headers' => response&.headers || {},
          'success' => success?
        },
        'error' => error_message
      }
    end

    def response
      @response ||= fetch
    rescue StandardError => e
      @error = e
      nil
    end

    private

    def fetch
      session = Faraday.new(url: url) do |faraday|
        # Configure retries based on available middleware
        faraday.request :retry, { max: @retries } if defined?(Faraday::Retry)

        # Configure redirect handling
        if @allow_redirections
          begin
            faraday.use FaradayMiddleware::FollowRedirects, limit: 10
            faraday.use :cookie_jar
          rescue NameError, NoMethodError
            # Continue without middleware if not available
          end
        end

        faraday.headers.merge!(@headers)
        faraday.adapter :net_http
      end

      # Manual retry mechanism as a backup
      retries = 0

      begin
        response = session.get do |req|
          req.options.timeout = @timeout
          req.options.open_timeout = @timeout
        end

        @url = response.env.url.to_s
        response
      rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
        retries += 1
        retry if retries <= @retries
        raise e
      end
    end

    def with_default_scheme(request)
      request.url && request.scheme.nil? ? "http://#{request.url}" : request.url
    end

    def page
      # Use URI.open instead of open for Ruby 3.0+ compatibility
      Nokogiri::HTML(URI.open(with_default_scheme(@request),
                              allow_redirections: :safe,
                              read_timeout: @timeout,
                              'User-Agent' => @headers['User-Agent']))
    end
  end
end
