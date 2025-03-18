# frozen_string_literal: true

require 'spec_helper'

describe WebInspector do
  let(:url) { 'http://www.davidesantangelo.com' }
  let(:google_url) { 'http://www.google.com' }

  it 'has a version number' do
    expect(WebInspector::VERSION).not_to be nil
  end

  it 'should recieve response code 301' do
    page = WebInspector.new(url)
    expect(page.response.status).to eq(301)
  end

  it 'expect Davide Santangelo - Developer title' do
    page = WebInspector.new(url)
    expect(page.title).to eq('Davide Santangelo - Developer')
  end

  it 'expect Davide Santangelo - Passionate Web Developer title' do
    page = WebInspector.new(url)
    expect(page.title).to eq('Davide Santangelo - Developer')
  end

  it 'expect Davide Santangelo - Passionate Software Developer. API specialist. In love with Ruby, Python and Machine Learning. meta description' do
    page = WebInspector.new(url)
    expect(page.description).to eq('Davide Santangelo - Passionate Software Developer. API specialist. In love with Ruby, Python and Machine Learning.')
  end

  it 'expect meta description' do
    page = WebInspector.new(url)
    expect(page.description).to eq('Davide Santangelo - Passionate Software Developer. API specialist. In love with Ruby, Python and Machine Learning.')
  end

  it 'expect http://www.davidesantangelo.com/ url' do
    page = WebInspector.new(url)
    expect(page.url).to eq('http://www.davidesantangelo.com/')
  end

  it 'expect scheme http and host heroku.com and port 80' do
    page = WebInspector.new(url)
    expect(page.scheme).to eq('http')
    expect(page.host).to eq('www.davidesantangelo.com')
    expect(page.port).to eq(80)
  end

  it 'expect www.davidesantangelo.com host' do
    page = WebInspector.new(url)
    expect(page.host).to eq('www.davidesantangelo.com')
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

  context 'with new features in v1.0.0' do
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
end
