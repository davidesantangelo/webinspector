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

    def links
      get_new_links unless @links
      return @links
    end
    
    # View only the links to a given domain
    # Use the page's domain as the default
    def domain_links(user_domain = @page.host)
      validated_domain_uri = validate_url("http://#{user_domain.downcase.gsub(/\s+/, '')}")
      raise "Invalid domain provided" unless validated_domain_uri
      
      domain = validated_domain_uri.host
      
      domain_links = []
      
      links.map do |l|
        u = validate_url(l)
        next unless u
        
        domain_links.push(l) if domain == u.host.downcase
      end 
      
      return domain_links.compact!
    end
    
    def validate_url(u)
      begin
        return URI.parse(u)
      rescue URI::InvalidURIError => e
        return false
      end
    end

    def images
      get_new_images unless @images
      return @images
    end

    private
    
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