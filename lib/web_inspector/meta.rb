# frozen_string_literal: true

module WebInspector
  class Meta
    def initialize(page)
      @page = page
    end

    def meta_tags
      {
        'name' => meta_tags_by('name'),
        'http-equiv' => meta_tags_by('http-equiv'),
        'property' => meta_tags_by('property'),
        'charset' => [charset_from_meta_charset],
        'itemprop' => meta_tags_by('itemprop') # Add support for schema.org microdata
      }
    end

    def meta_tag
      convert_each_array_to_first_element_on meta_tags
    end

    def meta
      meta_tag['name']
        .merge(meta_tag['http-equiv'])
        .merge(meta_tag['property'])
        .merge(meta_tag['itemprop'] || {})
        .merge('charset' => meta_tag['charset'])
        .merge('author' => author, 'publisher' => publisher)
    end

    def author
      meta_tag['name']['author'] || meta_tag['property']['article:author']
    rescue StandardError
      nil
    end

    def publisher
      meta_tag['property']['article:publisher'] || meta_tag['property']['og:site_name']
    rescue StandardError
      nil
    end

    def charset
      @charset ||= charset_from_meta_charset || charset_from_meta_content_type || charset_from_header || 'utf-8'
    end

    private

    def charset_from_meta_charset
      @page.css('meta[charset]')[0].attributes['charset'].value
    rescue StandardError
      nil
    end

    def charset_from_meta_content_type
      @page.css("meta[http-equiv='Content-Type']")[0].attributes['content'].value.split(';')[1].strip.split('=')[1]
    rescue StandardError
      nil
    end

    def charset_from_header
      # Try to get charset from Content-Type header if available
      nil
    end

    def meta_tags_by(attribute)
      hash = {}
      @page.css("meta[@#{attribute}]").map do |tag|
        name = begin
          tag.attributes[attribute].value.downcase
        rescue StandardError
          nil
        end
        content = begin
          tag.attributes['content'].value
        rescue StandardError
          nil
        end

        if name && content
          hash[name] ||= []
          hash[name] << content
        end
      end
      hash
    end

    def convert_each_array_to_first_element_on(hash)
      hash.each_pair do |k, v|
        hash[k] = if v.is_a?(Hash)
                    convert_each_array_to_first_element_on(v)
                  elsif v.is_a?(Array)
                    v.first
                  else
                    v
                  end
      end
    end
  end
end
