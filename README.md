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

#### JavaScript and Stylesheets

```ruby
page.javascripts  # array of all JavaScript files (absolute URLs)
page.stylesheets  # array of all CSS stylesheets (absolute URLs)
```

#### Language Detection

```ruby
page.language  # detected language code (e.g., "en", "es", "fr")
```

#### Structured Data

```ruby
page.structured_data  # array of JSON-LD structured data objects
page.microdata        # array of microdata items
page.json_ld          # alias for structured_data
```

#### Security Information

```ruby
page.security_info  # hash with security details: { secure: true, hsts: true, ... }
```

#### Performance Metrics

```ruby
page.load_time  # page load time in seconds
page.size       # page size in bytes
```

#### Content Type

```ruby
page.content_type  # content type header (e.g., "text/html; charset=utf-8")
```

#### Technology Detection

```ruby
page.technologies  # hash of detected technologies: { jquery: true, react: true, ... }
```

#### HTML Tag Statistics

```ruby
page.tag_count  # hash with counts of each HTML tag: { "div" => 45, "p" => 12, ... }
```

#### RSS/Atom Feeds

```ruby
page.feeds  # array of RSS/Atom feed URLs found on the page
```

#### Social Media Links

```ruby
page.social_links  # hash of social media profiles: { facebook: "url", twitter: "url", ... }
```

#### Robots.txt and Sitemap

```ruby
page.robots_txt_url  # URL to robots.txt
page.sitemap_url     # array of sitemap URLs
```

#### CMS Detection

```ruby
page.cms_info  # hash with CMS details: { name: "WordPress", version: "6.0", themes: [...], plugins: [...] }
```

#### Accessibility Score

```ruby
page.accessibility_score  # hash with score (0-100) and details: { score: 85, details: [...] }
```

#### Mobile-Friendly Check

```ruby
page.mobile_friendly?  # true if the page has viewport meta tag and responsive CSS
```

### Export all data to JSON

```ruby
page.to_hash # returns a hash with all page data
```

## Changelog

### Version 1.2.0

**New Features:**

- RSS/Atom feed detection with `feeds` method
- Social media profile extraction with `social_links` method
- CMS detection and information with `cms_info` method (WordPress, Drupal, Joomla, Shopify, Wix, Squarespace)
- Accessibility scoring with `accessibility_score` method
- Mobile-friendly detection with `mobile_friendly?` method
- Robots.txt and sitemap URL detection with `robots_txt_url` and `sitemap_url` methods

**Improvements:**

- Enhanced `Request` module with `valid?` and `ssl?` methods for better URL validation
- Improved `Meta` module with author and publisher extraction
- Better error handling across all modules
- Performance improvements with internal caching

## Contributors

- Steven Shelby ([@stevenshelby](https://github.com/stevenshelby))
- Sam Nissen ([@samnissen](https://github.com/samnissen))

## License

The WebInspector gem is released under the MIT License.

## Contributing

1. Fork it ( https://github.com/davidesantangelo/webinspector/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
