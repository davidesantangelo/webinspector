require File.expand_path(File.join(File.dirname(__FILE__), 'meta'))

module WebInspector
  class Inspector

    def initialize(page)
      @page = page
      @meta = WebInspector::Meta.new(page).meta
    end

    def title
      @page.css('title').inner_text.strip rescue nil
    end

    def description
      @meta['description'] || snippet
    end

    def body
      @page.css('body').to_html
    end

    def meta
      @meta
    end

    def find(words)
      text = @page.at('html').inner_text
      counter(text.downcase, words)
    end

    def links
      get_new_links unless @links
      return @links
    end

    def domain_links(user_domain, host)
      @host ||= host

      validated_domain_uri = validate_url_domain("http://#{user_domain.downcase.gsub(/\s+/, '')}")
      raise "Invalid domain provided" unless validated_domain_uri

      domain = validated_domain_uri.domain

      domain_links = []

      links.each do |l|

        u = validate_url_domain(l)
        next unless u && u.domain

        domain_links.push(l) if domain == u.domain.downcase
      end

      return domain_links.compact
    end

    def domain_images(user_domain, host)
      @host ||= host

      validated_domain_uri = validate_url_domain("http://#{user_domain.downcase.gsub(/\s+/, '')}")
      raise "Invalid domain provided" unless validated_domain_uri

      domain = validated_domain_uri.domain

      domain_images = []

      images.each do |img|
        u = validate_url_domain(img)
        next unless u && u.domain

        domain_images.push(img) if u.domain.downcase.end_with?(domain)
      end

      return domain_images.compact
    end

    # Normalize and validate the URLs on the page for comparison
    def validate_url_domain(u)
      # Enforce a few bare standards before proceeding
      u = "#{u}"
      u = "/" if u.empty?

      begin
        # Look for evidence of a host. If this is a relative link
        # like '/contact', add the page host.
        domained_url = @host + u unless (u.split("/").first || "").match(/(\:|\.)/)
        domained_url ||= u

        # http the URL if it is missing
        httpped_url = "http://" + domained_url unless domained_url[0..3] == 'http'
        httpped_url ||= domained_url

        # Make sure the URL parses
        uri = URI.parse(httpped_url)

        # Make sure the URL passes ICANN rules.
        # The PublicSuffix object splits the domain and subdomain
        # (unlike URI), which allows more liberal URL matching.
        return PublicSuffix.parse(uri.host)
      rescue URI::InvalidURIError, PublicSuffix::DomainInvalid
        return false
      end
    end

    def images
      get_new_images unless @images
      return @images
    end

    private

    def counter(text, words)
      results = []
      hash = Hash.new

      words.each do |word|
        hash[word] = text.scan(/#{word.downcase}/).size
        results.push(hash)
        hash = Hash.new
      end
      return results
    end

    def get_new_images
      @images = []
      @page.css("img").each do |img|
        @images.push((img[:src].to_s.start_with? @url.to_s) ? img[:src] : URI.join(url, img[:src]).to_s) if (img and img[:src])
      end
    end

    def get_new_links
      @links = []
      @page.css("a").each do |a|
        @links.push((a[:href].to_s.start_with? @url.to_s) ? a[:href] : URI.join(@url, a[:href]).to_s) if (a and a[:href])
      end
    end

    def snippet
      first_long_paragraph = @page.search('//p[string-length() >= 120]').first
      first_long_paragraph ? first_long_paragraph.text : ''
    end
  end
end
