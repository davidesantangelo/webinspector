# WebInspector

Ruby gem to inspect web pages. It scrapes a given URL and returns its title, description, meta tags, links, images, and more.

<a href="https://codeclimate.com/github/davidesantangelo/webinspector"><img src="https://codeclimate.com/github/davidesantangelo/webinspector/badges/gpa.svg" /></a>


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'webinspector'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install webinspector

## Usage

### Initialize a WebInspector instance

```ruby
page = WebInspector.new('http://example.com')
```

### With options

```ruby
page = WebInspector.new('http://example.com', {
  timeout: 30,                         # Request timeout in seconds (default: 30)
  retries: 3,                          # Number of retries (default: 3) 
  headers: {'User-Agent': 'Custom UA'} # Custom HTTP headers
})
```

### Accessing response status and headers

```ruby
page.response.status  # 200
page.response.headers # { "server"=>"apache", "content-type"=>"text/html; charset=utf-8", ... }
page.status_code      # 200
page.success?         # true if the page was loaded successfully
page.error_message    # returns the error message if any
```

### Accessing page data

```ruby
page.url           # URL of the page
page.scheme        # Scheme of the page (http, https)
page.host          # Hostname of the page (like, example.com, without the scheme)
page.port          # Port of the page
page.title         # title of the page from the head section
page.description   # description of the page
page.links         # array of all links found on the page (absolute URLs)
page.images        # array of all images found on the page (absolute URLs)
page.meta          # meta tags of the page
page.favicon       # favicon URL if available
```

### Working with meta tags

```ruby
page.meta                 # all meta tags
page.meta['description']  # meta description
page.meta['keywords']     # meta keywords
page.meta['og:title']     # OpenGraph title
```

### Filtering links and images by domain

```ruby
page.domain_links('example.com')  # returns only links pointing to example.com
page.domain_images('example.com') # returns only images hosted on example.com
```

### Searching for words

```ruby
page.find(["ruby", "rails"]) # returns [{"ruby"=>3}, {"rails"=>1}]
```

### Export all data to JSON

```ruby
page.to_hash # returns a hash with all page data
```

## Contributors

  * Steven Shelby ([@stevenshelby](https://github.com/stevenshelby))
  * Sam Nissen ([@samnissen](https://github.com/samnissen))

## License

The WebInspector gem is released under the MIT License.

## Contributing

1. Fork it ( https://github.com/davidesantangelo/webinspector/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
