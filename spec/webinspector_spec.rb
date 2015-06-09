require 'spec_helper'

describe WebInspector do
	let(:url) { "http://www.davidesantangelo.com" }

  it 'has a version number' do
    expect(WebInspector::VERSION).not_to be nil
  end

  it 'should recieve response code 200' do
    page = WebInspector.new(url)
    expect(page.response.status).to eq(200)
  end

  it 'expect Davide Santangelo - Passionate Web Developer title' do
  	page = WebInspector.new(url)
    expect(page.title).to eq("Davide Santangelo - Passionate Web Developer")
  end

  it 'expect Davide Santangelo - Passionate Web Developer. API specialist. In love with Ruby. meta description' do 
    page = WebInspector.new(url)
    expect(page.description).to eq("Davide Santangelo - Passionate Web Developer. API specialist. In love with Ruby.")
  end

  it 'expect http://www.davidesantangelo.com/ url' do
  	page = WebInspector.new(url)
    expect(page.url).to eq("http://www.davidesantangelo.com/")
  end

  it 'expect scheme http and host heroku.com and port 80' do
  	page = WebInspector.new(url)
    expect(page.scheme).to eq("http")
    expect(page.host).to eq("www.davidesantangelo.com")
    expect(page.port).to eq(80)
  end

  it 'expect www.davidesantangelo.com host' do
    page = WebInspector.new(url)
    expect(page.host).to eq("www.davidesantangelo.com")
  end

  it 'expect links.size > 0' do
    page = WebInspector.new(url)
    expect(page.links.size).to be > 0
  end

  it 'expect body content length > 0' do
    page = WebInspector.new(url)
    expect(page.body.length).to be > 0
  end
  
  it 'expect domain images to include all images hosted at the domain' do
    page = WebInspector.new("http://www.google.com") #=> davidesantangelo.com has no images...
    
    da_images = page.images.map{|l| 
      l if ("#{l}".start_with?("/") && "#{l}".match(/\A(htt(ps|p)\:\/\/(www\.google\.com|google\.com)|(www\.google\.com|google\.com))|\//))
    }.compact
    
    # Our regular expression is theoretically more forgiving than our URL validation.
    # So, we should expect that the links it finds to be gt or equal to the `page.links`.
    expect(da_images.size).to be >= page.domain_images.size
  end
  
  it 'expect domain links to include all links pointed at the domain' do
    page = WebInspector.new(url)
    da_links = page.links.map{|l| 
      l if ("#{l}".start_with?("/") && "#{l}".match(/\A(htt(ps|p)\:\/\/(www\.davidesantangelo\.com|davidesantangelo\.com)|(www\.davidesantangelo\.com|davidesantangelo\.com))|\//))
    }.compact
    
    # Our regular expression is theoretically more forgiving than our URL validation.
    # So, we should expect that the links it finds to be gt or equal to the `page.links`.
    expect(da_links.size).to be >= page.domain_links.size
  end
end
