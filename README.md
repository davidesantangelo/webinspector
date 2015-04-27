# Webinspector

Ruby gem to inspect completely a web page. It scrapes a given URL, and returns you its title, description, meta, links, images and more.

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

Initialize a WebInspector instance for an URL, like this:

```ruby
page = WebInspector.new('http://davidesantangelo.com')
```

## Accessing response status and headers

You can check the status and headers from the response like this:

```ruby
page.response.status  # 200
page.response.headers # { "server"=>"nginx", "content-type"=>"text/html; charset=utf-8", "cache-control"=>"must-revalidate, private, max-age=0", ... }
```

## Accessing inpsected data

You can see the data like this:

```ruby
page.url                 # URL of the page
page.scheme              # Scheme of the page (http, https)
page.host                # Hostname of the page (like, davidesantangelo.com, without the scheme)
page.title               # title of the page from the head section, as string
page.links          		 # every link found
page.meta['keywords']    # meta keywords, as string
page.meta['description'] # meta description, as string
page.description         # returns the meta description, or the first long paragraph if no meta description is found
page.images              # enumerable collection, with every img found on the page as an absolute URL
```

## License
The restcountry GEM is released under the MIT License.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/webinspector/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
