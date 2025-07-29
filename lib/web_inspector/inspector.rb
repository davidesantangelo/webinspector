# frozen_string_literal: true

require File.expand_path(File.join(File.dirname(__FILE__), 'meta'))

module WebInspector
  class Inspector
    attr_reader :page, :url, :host, :meta

    def initialize(page)
      @page = page
      @meta = WebInspector::Meta.new(page).meta
      @base_url = nil
    end

    def set_url(url, host)
      @url = url
      @host = host
    end

    def title
      @page.css('title').inner_text.strip
    rescue StandardError
      nil
    end

    def description
      @meta['description'] || @meta['og:description'] || snippet
    end

    def body
      @page.css('body').to_html
    end

    # Search for specific words in the page content
    # @param words [Array<String>] List of words to search for
    # @return [Array<Hash>] Counts of word occurrences
    def find(words)
      text = @page.at('html').inner_text
      counter(text.downcase, words)
    end

    # Get all links from the page
    # @return [Array<String>] Array of URLs
    def links
      @links ||= begin
        links = []
        @page.css('a').each do |a|
          href = a[:href]
          next unless href

          # Skip javascript and mailto links
          next if href.start_with?('javascript:', 'mailto:', 'tel:')

          # Clean and normalize URL
          href = href.strip

          begin
            absolute_url = make_absolute_url(href)
            links << absolute_url if absolute_url
          rescue URI::InvalidURIError
            # Skip invalid URLs
          end
        end
        links.uniq
      end
    end

    # Get links from a specific domain
    # @param user_domain [String] Domain to filter links by
    # @param host [String] Current host
    # @return [Array<String>] Filtered links
    def domain_links(user_domain, host = nil)
      @host ||= host
      filter_by_domain(links, user_domain)
    end

    # Get all images from the page
    # @return [Array<String>] Array of image URLs
    def images
      @images ||= begin
        images = []
        @page.css('img').each do |img|
          src = img[:src]
          next unless src

          # Clean and normalize URL
          src = src.strip

          begin
            absolute_url = make_absolute_url(src)
            images << absolute_url if absolute_url
          rescue URI::InvalidURIError, URI::BadURIError
            # Skip invalid URLs
          end
        end
        images.uniq.compact
      end
    end

    # Get images from a specific domain
    # @param user_domain [String] Domain to filter images by
    # @param host [String] Current host
    # @return [Array<String>] Filtered images
    def domain_images(user_domain, host = nil)
      @host ||= host
      filter_by_domain(images, user_domain)
    end

    # Get all JavaScript files used by the page
    # @return [Array<String>] Array of JavaScript file URLs
    def javascripts
      @javascripts ||= begin
        scripts = []
        @page.css('script[src]').each do |script|
          src = script[:src]
          next unless src

          # Clean and normalize URL
          src = src.strip

          begin
            absolute_url = make_absolute_url(src)
            scripts << absolute_url if absolute_url
          rescue URI::InvalidURIError, URI::BadURIError
            # Skip invalid URLs
          end
        end
        scripts.uniq.compact
      end
    end

    # Get stylesheets used by the page
    # @return [Array<String>] Array of CSS file URLs
    def stylesheets
      @stylesheets ||= begin
        styles = []
        @page.css('link[rel="stylesheet"]').each do |style|
          href = style[:href]
          next unless href

          # Clean and normalize URL
          href = href.strip

          begin
            absolute_url = make_absolute_url(href)
            styles << absolute_url if absolute_url
          rescue URI::InvalidURIError, URI::BadURIError
            # Skip invalid URLs
          end
        end
        styles.uniq.compact
      end
    end

    # Detect the page language
    # @return [String, nil] Language code if detected, nil otherwise
    def language
      # Check for html lang attribute first
      html_tag = @page.at('html')
      return html_tag['lang'] if html_tag && html_tag['lang'] && !html_tag['lang'].empty?

      # Then check for language meta tag
      lang_meta = @meta['content-language']
      return lang_meta if lang_meta && !lang_meta.empty?

      # Fallback to inspecting content headers if available
      nil
    end

    # Extract structured data (JSON-LD) from the page
    # @return [Array<Hash>] Array of structured data objects
    def structured_data
      @structured_data ||= begin
        data = []
        @page.css('script[type="application/ld+json"]').each do |script|
          parsed = JSON.parse(script.text)
          data << parsed if parsed
        rescue JSON::ParserError
          # Skip invalid JSON
        end
        data
      end
    end

    # Extract microdata from the page
    # @return [Array<Hash>] Array of microdata items
    def microdata
      @microdata ||= begin
        items = []
        @page.css('[itemscope]').each do |scope|
          item = { type: scope['itemtype'] }
          properties = {}

          scope.css('[itemprop]').each do |prop|
            name = prop['itemprop']
            # Extract value based on tag
            value = case prop.name.downcase
                    when 'meta'
                      prop['content']
                    when 'img', 'audio', 'embed', 'iframe', 'source', 'track', 'video'
                      make_absolute_url(prop['src'])
                    when 'a', 'area', 'link'
                      make_absolute_url(prop['href'])
                    when 'time'
                      prop['datetime'] || prop.text.strip
                    else
                      prop.text.strip
                    end
            properties[name] = value
          end

          item[:properties] = properties
          items << item
        end
        items
      end
    end

    # Count all tag types on the page
    # @return [Hash] Counts of different HTML elements
    def tag_count
      tags = {}
      @page.css('*').each do |element|
        tag_name = element.name.downcase
        tags[tag_name] ||= 0
        tags[tag_name] += 1
      end
      tags
    end

    private

    # Count occurrences of words in text
    # @param text [String] Text to search in
    # @param words [Array<String>] Words to find
    # @return [Array<Hash>] Count results
    def counter(text, words)
      words.map do |word|
        { word => text.scan(/#{Regexp.escape(word.downcase)}/).size }
      end
    end

    # Validate a URL domain
    # @param u [String] URL to validate
    # @return [PublicSuffix::Domain, false] Domain object or false if invalid
    def validate_url_domain(u)
      u = u.to_s
      u = '/' if u.empty?

      begin
        domained_url = if !(u.split('/').first || '').match(/(:|\.)/)
                         @host + u
                       else
                         u
                       end

        httpped_url = domained_url.start_with?('http') ? domained_url : "http://#{domained_url}"
        uri = URI.parse(httpped_url)

        PublicSuffix.parse(uri.host)
      rescue URI::InvalidURIError, PublicSuffix::DomainInvalid
        false
      end
    end

    # Filter a list of URLs by a given domain.
    # @param collection [Array<String>] The list of URLs to filter.
    # @param user_domain [String] The domain to filter by.
    # @return [Array<String>] The filtered list of URLs.
    def filter_by_domain(collection, user_domain)
      return [] if collection.empty?

      # Handle nil user_domain
      user_domain = @host.to_s if user_domain.nil? || user_domain.empty?

      # Normalize domain for comparison
      normalized_domain = user_domain.to_s.downcase.gsub(/\s+/, '').sub(/^www\./, '')

      collection.select do |item|
        uri = URI.parse(item.to_s)
        next false unless uri.host

        uri_host = uri.host.to_s.downcase.sub(/^www\./, '')
        uri_host.include?(normalized_domain)
      rescue URI::InvalidURIError, NoMethodError
        false
      end
    end

    # Make a URL absolute
    # @param url [String] URL to make absolute
    # @return [String, nil] Absolute URL or nil if invalid
    def make_absolute_url(url)
      return nil if url.nil? || url.empty?

      # If it's already absolute, return it
      return url if url.start_with?('http://', 'https://')

      # Get base URL from the page if not already set
      if @base_url.nil?
        base_tag = @page.at_css('base[href]')
        @base_url = base_tag ? base_tag['href'] : ''
      end

      begin
        # Try joining with base URL first if available
        return URI.join(@base_url, url).to_s unless @base_url.empty?
      rescue URI::InvalidURIError, URI::BadURIError
        # Fall through to next method
      end

      begin
        # If we have @url, try to use it
        return URI.join(@url, url).to_s if @url
      rescue URI::InvalidURIError, URI::BadURIError
        # Fall through to next method
      end

      # For relative URLs, we need to make our best guess
      return "http://#{@host}#{url}" if url.start_with?('/')
      return "http://#{@host}/#{url}" if @host

      # Last resort, return the original
      url
    rescue URI::InvalidURIError, URI::BadURIError
      url # Return original instead of nil to be more lenient
    end

    # Extract a snippet from the first long paragraph
    # @return [String] Text snippet
    def snippet
      first_long_paragraph = @page.search('//p[string-length() >= 120]').first
      first_long_paragraph ? first_long_paragraph.text.strip[0..255] : ''
    end
  end
end
