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

      return [] if links.empty?

      # Handle nil user_domain
      user_domain = @host.to_s if user_domain.nil? || user_domain.empty?

      # Normalize domain for comparison
      user_domain = user_domain.to_s.downcase.gsub(/\s+/, '')
      user_domain = user_domain.sub(/^www\./, '') # Remove www prefix for comparison

      links.select do |link|
        uri = URI.parse(link.to_s)
        next false unless uri.host # Skip URLs without hosts

        uri_host = uri.host.to_s.downcase
        uri_host = uri_host.sub(/^www\./, '') # Remove www prefix for comparison
        uri_host.include?(user_domain)
      rescue URI::InvalidURIError, NoMethodError
        false
      end
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

      return [] if images.empty?

      # Handle nil user_domain
      user_domain = @host.to_s if user_domain.nil? || user_domain.empty?

      # Normalize domain for comparison
      user_domain = user_domain.to_s.downcase.gsub(/\s+/, '')
      user_domain = user_domain.sub(/^www\./, '') # Remove www prefix for comparison

      images.select do |img|
        uri = URI.parse(img.to_s)
        next false unless uri.host # Skip URLs without hosts

        uri_host = uri.host.to_s.downcase
        uri_host = uri_host.sub(/^www\./, '') # Remove www prefix for comparison
        uri_host.include?(user_domain)
      rescue URI::InvalidURIError, NoMethodError
        false
      end
    end

    private

    # Count occurrences of words in text
    # @param text [String] Text to search in
    # @param words [Array<String>] Words to find
    # @return [Array<Hash>] Count results
    def counter(text, words)
      words.map do |word|
        { word => text.scan(/#{word.downcase}/).size }
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
        @base_url = base_tag ? base_tag['href'] : nil
      end

      begin
        # Try joining with base URL first if available
        if @base_url && !@base_url.empty?
          begin
            return URI.join(@base_url, url).to_s
          rescue URI::InvalidURIError, URI::BadURIError
            # Fall through to next method
          end
        end

        # If we have @url, try to use it
        if @url
          begin
            return URI.join(@url, url).to_s
          rescue URI::InvalidURIError, URI::BadURIError
            # Fall through to next method
          end
        end

        # Otherwise use a default http:// base if url is absolute path
        return "http://#{@host}#{url}" if url.start_with?('/')

        # For truly relative URLs with no base, we need to make our best guess
        return "http://#{@host}/#{url}" if @host

        # Last resort, return the original
        url
      rescue URI::InvalidURIError, URI::BadURIError
        url # Return original instead of nil to be more lenient
      end
    end

    # Extract a snippet from the first long paragraph
    # @return [String] Text snippet
    def snippet
      first_long_paragraph = @page.search('//p[string-length() >= 120]').first
      first_long_paragraph ? first_long_paragraph.text.strip[0..255] : ''
    end
  end
end
