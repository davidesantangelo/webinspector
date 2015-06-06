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


  # added tests
  it 'expect first blog entry on page' do
    first_blog = "Today I want to talk you about TUNSTUNS is a funny open source personal project (Rails + Slim + SASS + Sidekiq + Bootstrap + JS). It allow you to keep track of your twitter unffollower. With TUNS you will receive a notification when someone unfollow or return to follow you back.After it is launched on Product Hunt he has been a great success. At the moment more then 500 users and 1100 unfollower notification :). Obviously i'm working on new features and improvements to offer to the user a useful, clean and funny service. if you want to try and tell me what you think, feedbacks are always welcome!"
    page = WebInspector.new("http://www.davidesantangelo.com/blog")
    expect(page.first_blog_post_content).to eq(first_blog)
  end

  it 'expect first title to equal - TUNS' do
    page = WebInspector.new("http://www.davidesantangelo.com/blog")
    expect(page.all_posts[0][:title]).to eq('TUNS')
  end

  it 'expect first blog title of another blog' do
    page = WebInspector.new("http://www.colinw.info/posts")
    expect(page.all_posts.length).to be > 0
    pp "Post Title: #{page.all_posts[0][:title]}"
  end

end
