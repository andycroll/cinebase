# Cinebase

[![](https://img.shields.io/gem/v/cinebase.svg)](http://rubygems.org/gems/cinebase)
![](https://img.shields.io/github/license/andycroll/cinebase.svg)

A basic interface for a series of cinema gems.

## Installation

Add this line to the gem's gemspec:

```ruby
gem.add_runtime_dependency 'cinebase'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cinebase

## Usage

This gem is intended to act as a base for other cinema chain gems. Inherit the classes to get the correct method signatures.

```ruby
module CinemaChainName
  class Cinema < Cinebase::Cinema
    def self.all(cinema_id)
      # parse webpages or apis to get cinemas
    end

    def brand
      # 'Brand Name'
    end

    # define address methods

    def latitude
      # Float in decimal degrees, or nil when unknown (the default)
    end

    def longitude
      # Float in decimal degrees, or nil when unknown (the default)
    end
  end
end

module CinemaChainName
  class Performance < Cinebase::Performance
    def self.at(cinema_id)
      # parse webpages or apis to get performances for a cinema, built with
      # booking_url:, cinema_id:, cinema_name:, dimension:, festival:,
      # film_name:, film_year:, language:, starting_at: and variant:
    end
  end
end

module CinemaChainName
  module Internal
    class TitleSanitizer < Cinebase::TitleSanitizer
      private

      # Chain patterns first, so markers like trailing sing-alongs are at the
      # end of the title by the time the common rules run
      def remove
        [] + COMMON_REMOVE # chain-specific patterns, then the common ones
      end

      def replace
        {}.merge(COMMON_REPLACE) # { core title regex => replacement text }
      end
    end
  end
end
```

### Festivals

A festival is an annual event, so `Cinebase::Festival` holds the name and the
edition year. Pass it to a performance as `festival:`.

```ruby
Cinebase::Festival.from_title('Cine-Excess 2026: Scum Of The Earth', year: 2026)
#=> #<data Cinebase::Festival name="Cine-Excess", year=2026>

# No year in the title, so the screening's year is the edition
Cinebase::Festival.from_title('UKJFF - From Cable Street To Brick Lane', year: 2026)
#=> #<data Cinebase::Festival name="UKJFF", year=2026>
```

`COMMON_REMOVE` strips the same prefixes from titles.

### Film years

Titles often end with the film's year. `COMMON_REMOVE` strips it, and
`TitleSanitizer.film_year` reads it so it can be passed as `film_year:`:

```ruby
Cinebase::TitleSanitizer.film_year('Street Fighter (2026)')               #=> 2026
Cinebase::TitleSanitizer.film_year('Kung Fu Soccer (2026) (Dubbed)')     #=> 2026
Cinebase::TitleSanitizer.film_year('Blade Runner 2049')                  #=> nil
```

For a re-release this is the original year, which is what IMDb lists.

### Vista OCAPI chains

Chains whose websites run on Vista share a client, guest token retrieval and
packaging. These are not loaded by `require 'cinebase'`:

```ruby
require 'cinebase/vista'

client = Cinebase::Vista::Client.new(
  base_url: 'https://vwc.odeon.co.uk/WSVistaWebClient/ocapi/v1/',
  region_code: 'UK',
  token: guest_jwt
)
client.get('sites')

module CinemaChainName
  class GuestToken < Cinebase::Vista::GuestToken
    PAGE_URL = 'https://www.example.co.uk/page-with-the-token/'.freeze

    private

    def bundled_curl
      File.expand_path('../../vendor/curl-impersonate/bin/curl-impersonate', __dir__)
    end

    def extract_token(html)
      # return the guest JWT from the page
    end
  end
end
```

`GuestToken#fetch` runs `curl-impersonate` with a Chrome profile, checks the
token's declared expiry and raises `Cinebase::Vista::AuthenticationError` when
it cannot get a current token. To ship curl-impersonate inside platform gems,
add this to the chain gem's Rakefile:

```ruby
require 'cinebase/vista/package_task'
Cinebase::Vista::PackageTask.new('chain_name.gemspec')
# rake 'package:native[arm64-darwin]' or rake package:all
```

## Contributing

1. [Fork it](https://github.com/andycroll/cinebase/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
