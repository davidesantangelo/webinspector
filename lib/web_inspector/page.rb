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
    attr_reader :status_code

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
    %i[title description body links images meta javascripts stylesheets language structured_data microdata
       tag_count].each do |method|
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

    # Get information about the page's security
    # @return [Hash] Security information
    def security_info
      return @security_info if defined?(@security_info)

      @security_info = {
        secure: scheme == 'https',
        hsts: response&.headers && response.headers['strict-transport-security'] ? true : false,
        content_security_policy: response&.headers && response.headers['content-security-policy'] ? true : false
      }

      # Extract SSL/TLS info if available and using HTTPS
      if scheme == 'https' && response&.env&.response_headers
        @security_info[:ssl_version] = response.env[:ssl_version]
        @security_info[:cipher_suite] = response.env[:cipher_suite]
      end

      @security_info
    end

    # Get the content type of the page
    # @return [String, nil] Content type
    def content_type
      response&.headers && response.headers['content-type']
    end

    # Get the size of the page in bytes
    # @return [Integer, nil] Size in bytes
    def size
      return @size if defined?(@size)

      @size = if response&.headers && response.headers['content-length']
                response.headers['content-length'].to_i
              elsif response&.body
                response.body.bytesize
              end
    end

    # Get the load time of the page in seconds
    # @return [Float, nil] Load time in seconds
    attr_reader :load_time

    # Get all JSON-LD structured data as a hash
    # @return [Array<Hash>] Structured data
    def json_ld
      structured_data
    end

    # Get a hash of all technologies detected on the page
    # @return [Hash] Detected technologies
    def technologies
      techs = {}
      js_files = javascripts || []
      css_files = stylesheets || []
      page_body = body || ''
      page_meta = meta || {}
      response_headers = response&.headers || {}

      # Frameworks and Libraries
      techs[:jquery] = true if js_files.any? { |js| js.include?('jquery') } || page_body.include?('jQuery')
      techs[:react] = true if page_body.include?('data-reactroot') || js_files.any? { |js| js.include?('react') }
      techs[:vue] = true if page_body.include?('data-v-app') || js_files.any? { |js| js.include?('vue') }
      techs[:angular] = true if page_body.include?('ng-version') || js_files.any? { |js| js.include?('angular') }
      techs[:bootstrap] = true if css_files.any? do |css|
        css.include?('bootstrap')
      end || page_body.include?('class="container"')
      if response_headers['x-powered-by']&.include?('Rails') || response_headers.key?('x-rails-env')
        techs[:rails] =
          true
      end
      techs[:php] = true if response_headers['x-powered-by']&.include?('PHP')

      # CMS
      techs[:wordpress] = true if page_meta['generator']&.include?('WordPress') || page_body.include?('/wp-content/')
      techs[:shopify] = true if page_body.include?('Shopify.shop')

      # Analytics
      techs[:google_analytics] = true if js_files.any? { |js| js.include?('google-analytics.com') }

      # Server
      server = response_headers['server']
      if server
        techs[:server] = server
        techs[:nginx] = true if server.include?('nginx')
        techs[:apache] = true if server.include?('Apache')
        techs[:iis] = true if server.include?('IIS')
        techs[:express] = true if response_headers['x-powered-by']&.include?('Express')
      end

      techs
    end

    # Get full JSON representation of the page with all new data
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
        'javascripts' => javascripts,
        'stylesheets' => stylesheets,
        'favicon' => favicon,
        'language' => language,
        'structured_data' => structured_data,
        'microdata' => microdata,
        'security_info' => security_info,
        'content_type' => content_type,
        'size' => size,
        'load_time' => load_time,
        'technologies' => technologies,
        'tag_count' => tag_count,
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
      start_time = Time.now

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
        @load_time = Time.now - start_time
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
