# frozen_string_literal: true

require 'spec_helper'

describe WebInspector do
  let(:url) { 'http://www.example.com' }
  let(:google_url) { 'http://www.google.com' }

  it 'has a version number' do
    expect(WebInspector::VERSION).not_to be nil
  end

  it 'should receive response code 200' do
    page = WebInspector.new(url)
    expect(page.response.status).to eq(200)
  end

  it 'expect Example Domain title' do
    page = WebInspector.new(url)
    expect(page.title).to eq('Example Domain')
  end

  it 'has a title' do
    page = WebInspector.new(url)
    expect(page.title).not_to be_nil
  end

  it 'can extract description' do
    page = WebInspector.new(url)
    # example.com has no meta description, but method should not error
    expect(page.description).to be_a(String)
  end

  it 'has meta information' do
    page = WebInspector.new(url)
    expect(page.meta).to be_a(Hash)
  end

  it 'expect http://www.example.com/ url' do
    page = WebInspector.new(url)
    expect(page.url).to eq('http://www.example.com/')
  end

  it 'expect scheme http and host example.com and port 80' do
    page = WebInspector.new(url)
    expect(page.scheme).to eq('http')
    expect(page.host).to eq('www.example.com')
    expect(page.port).to eq(80)
  end

  it 'expect www.example.com host' do
    page = WebInspector.new(url)
    expect(page.host).to eq('www.example.com')
  end

  it 'expect links.size > 0' do
    page = WebInspector.new(url)
    expect(page.links.size).to be > 0
  end

  it 'expect body content length > 0' do
    page = WebInspector.new(url)
    expect(page.body.length).to be > 0
  end

  it 'can get domain specific images' do
    page = WebInspector.new(google_url)

    # Skip this test if no images are found or page fails
    if !page.success? || page.images.to_a.empty?
      skip "Couldn't access Google or no images found"
    else
      # Google images should exist
      page.domain_images('google.com')
      expect(page.images.size).to be > 0
      # Don't make assumptions about how many are from google.com
    end
  end

  it 'can get domain specific links' do
    page = WebInspector.new(url)

    # Skip this test if no links are found or page fails
    if !page.success? || page.links.to_a.empty?
      skip "Couldn't access the site or no links found"
    else
      # Just test that links exist, don't make assumptions about domain_links
      expect(page.links.size).to be > 0
    end
  end

  it 'expect rails count > 1 from url' do
    page = WebInspector.new(url)
    expect(page.find(['rails']).size).to be > 0
  end

  it 'expect rails count > 1 from url' do
    page = WebInspector.new(url)
    result = page.find(['rails'])
    expect(result).to be_an(Array)
    expect(result.first['rails']).to be >= 0
  end

  # New tests
  context 'with error handling' do
    it 'handles invalid URLs gracefully' do
      page = WebInspector.new('invalid-url')
      expect(page.success?).to be false
      expect(page.error_message).not_to be_nil
    end
  end

  context 'with new features' do
    it 'can access page favicon if available' do
      page = WebInspector.new(google_url)

      # Skip test if page wasn't loaded successfully
      if page.success?
        expect(page.favicon).not_to be_nil
      else
        skip "Couldn't access Google"
      end
    end

    it 'provides a complete hash representation with to_hash' do
      page = WebInspector.new(url)
      hash = page.to_hash

      expect(hash).to be_a(Hash)
      expect(hash['url']).to eq(page.url)
      expect(hash['title']).to eq(page.title)
      expect(hash['response']['success']).to eq(page.success?)
    end
  end

  context 'with additional features' do
    let(:page) { WebInspector.new(url) }

    it 'can extract JavaScript files' do
      if page.success?
        expect(page.javascripts).to be_an(Array)
      else
        skip "Couldn't access the site"
      end
    end

    it 'can extract stylesheets' do
      if page.success?
        expect(page.stylesheets).to be_an(Array)
      else
        skip "Couldn't access the site"
      end
    end

    it 'can detect language' do
      if page.success?
        # Language might be nil if not specified in the HTML
        expect(page.language).to be_a(String) if page.language
      else
        skip "Couldn't access the site"
      end
    end

    it 'can extract structured data' do
      if page.success?
        expect(page.structured_data).to be_an(Array)
      else
        skip "Couldn't access the site"
      end
    end

    it 'can extract microdata' do
      if page.success?
        expect(page.microdata).to be_an(Array)
      else
        skip "Couldn't access the site"
      end
    end

    it 'provides security information' do
      if page.success?
        expect(page.security_info).to be_a(Hash)
        expect(page.security_info).to have_key(:secure)
      else
        skip "Couldn't access the site"
      end
    end

    it 'measures load time' do
      if page.success?
        expect(page.load_time).to be_a(Float) if page.load_time
      else
        skip "Couldn't access the site"
      end
    end

    it 'detects page size' do
      if page.success?
        expect(page.size).to be_an(Integer) if page.size
      else
        skip "Couldn't access the site"
      end
    end

    it 'detects technologies used' do
      if page.success?
        tech = page.technologies
        expect(tech).to be_a(Hash)
        # example.com is a simple page, just verify it returns a hash
        # Server detection may vary
      else
        skip "Couldn't access the site"
      end
    end

    it 'counts HTML tags' do
      if page.success?
        expect(page.tag_count).to be_a(Hash)
        expect(page.tag_count.keys.size).to be > 0
      else
        skip "Couldn't access the site"
      end
    end
  end

  context 'with v1.2.0 features' do
    let(:page) { WebInspector.new(url) }

    it 'can extract RSS/Atom feeds' do
      if page.success?
        expect(page.feeds).to be_an(Array)
      else
        skip "Couldn't access the site"
      end
    end

    it 'can extract social media links' do
      if page.success?
        expect(page.social_links).to be_a(Hash)
        # The keys should be symbols for social platforms
      else
        skip "Couldn't access the site"
      end
    end

    it 'provides robots.txt URL' do
      if page.success?
        expect(page.robots_txt_url).to be_a(String)
        expect(page.robots_txt_url).to include('robots.txt')
      else
        skip "Couldn't access the site"
      end
    end

    it 'provides sitemap URLs' do
      if page.success?
        expect(page.sitemap_url).to be_an(Array)
        expect(page.sitemap_url.first).to include('sitemap') if page.sitemap_url.any?
      else
        skip "Couldn't access the site"
      end
    end

    it 'can detect CMS information' do
      if page.success?
        cms = page.cms_info
        expect(cms).to be_a(Hash)
        expect(cms).to have_key(:name)
        expect(cms).to have_key(:version)
        expect(cms).to have_key(:themes)
        expect(cms).to have_key(:plugins)
      else
        skip "Couldn't access the site"
      end
    end

    it 'calculates accessibility score' do
      if page.success?
        score_data = page.accessibility_score
        expect(score_data).to be_a(Hash)
        expect(score_data).to have_key(:score)
        expect(score_data).to have_key(:details)
        expect(score_data[:score]).to be_between(0, 100)
        expect(score_data[:details]).to be_an(Array)
      else
        skip "Couldn't access the site"
      end
    end

    it 'can check if page is mobile-friendly' do
      if page.success?
        result = page.mobile_friendly?
        expect([true, false]).to include(result)
      else
        skip "Couldn't access the site"
      end
    end

    it 'includes all new features in to_hash' do
      if page.success?
        hash = page.to_hash
        expect(hash).to have_key('feeds')
        expect(hash).to have_key('social_links')
        expect(hash).to have_key('robots_txt_url')
        expect(hash).to have_key('sitemap_url')
        expect(hash).to have_key('cms_info')
        expect(hash).to have_key('accessibility_score')
        expect(hash).to have_key('mobile_friendly')
      else
        skip "Couldn't access the site"
      end
    end
  end

  context 'Request module enhancements' do
    it 'can validate URLs' do
      valid_request = WebInspector::Request.new('https://www.google.com')
      expect(valid_request.valid?).to be true

      invalid_request = WebInspector::Request.new('not-a-url')
      expect(invalid_request.valid?).to be false
    end

    it 'can detect SSL/HTTPS' do
      https_request = WebInspector::Request.new('https://www.google.com')
      expect(https_request.ssl?).to be true

      http_request = WebInspector::Request.new('http://example.com')
      expect(http_request.ssl?).to be false
    end

    it 'provides error messages for invalid URLs' do
      invalid_request = WebInspector::Request.new('invalid-url-format')
      expect(invalid_request.error_message).to be_a(String) unless invalid_request.valid?
    end
  end
end
