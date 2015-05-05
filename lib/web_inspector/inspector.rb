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

    def meta
      @meta
    end

    def links
      links = []
      @page.css("a").each do |a|
        links.push((a[:href].to_s.start_with? @url.to_s) ? a[:href] : URI.join(@url, a[:href]).to_s) if (a and a[:href])
      end
      return links
    end

    def images
      images = []
      @page.css("img").each do |img|
        images.push((img[:src].to_s.start_with? @url.to_s) ? img[:src] : URI.join(url, img[:src]).to_s) if (img and img[:src])
      end
      return images
    end

    private

    def snippet
      first_long_paragraph = @page.search('//p[string-length() >= 120]').first
      first_long_paragraph ? first_long_paragraph.text : ''
    end
  end
end