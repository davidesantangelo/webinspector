module WebInspector
  class Inspector

  	def initialize(page)
  		@page = page
  	end

  	def title
  		@page.css('title').text.strip
  	end

  	def description
  		meta('description')
  	end

  	private

  	def meta(name)
	    metatags = []
	    return metatags unless @page.at("meta[name='#{name}']")

	    @page.at("meta[name='#{name}']").each do |meta|
	      metatags.push(meta[1]) if (meta and meta.include? "content")
	    end
	    return metatags
	  end
  end
end