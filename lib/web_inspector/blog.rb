require File.expand_path(File.join(File.dirname(__FILE__), 'meta'))

module WebInspector
  class Blog

    def initialize(page)
      @page = page
    end

    def first_blog_post_content
      @page.css('div.post')[0].css('p').text
    end

    def all_posts
      if @page.css('div.post').empty?
        if @page.css('div.content').empty?
          @page = false
        else
          @page.css('div.content')
        end
      else
        @page.css('div.post')
      end
    end

  end
end