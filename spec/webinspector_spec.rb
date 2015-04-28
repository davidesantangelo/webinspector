require 'spec_helper'

describe WebInspector do
	let(:url) { "http://www.davidesantangelo.com" }

  it 'has a version number' do
    expect(WebInspector::VERSION).not_to be nil
  end

  it 'expect Davide Santangelo - Passionate Web Developer title from davidesantangelo.com page' do
  	page = WebInspector.new(url)
    expect(page.title).to eq("Davide Santangelo - Passionate Web Developer")
  end

  it 'expect Davide Santangelo - Passionate Web Developer. In love with Ruby description from davidesantangelo.com page' do
    page = WebInspector.new(url)
    expect(page.description).to eq("Davide Santangelo - Passionate Web Developer. In love with Ruby")
  end

  it 'expect http://www.davidesantangelo.com/ url from davidesantangelo.com page' do
  	page = WebInspector.new(url)
    expect(page.url).to eq("http://www.davidesantangelo.com/")
  end

  it 'expect scheme http and host heroku.com and port 80 from davidesantangelo.com page' do
  	page = WebInspector.new(url)
    expect(page.scheme).to eq("http")
    expect(page.host).to eq("www.davidesantangelo.com")
    expect(page.port).to eq(80)
  end

  it 'expect www.davidesantangelo.com host from davidesantangelo.com page' do
    page = WebInspector.new(url)
    expect(page.host).to eq("www.davidesantangelo.com")
  end
end
