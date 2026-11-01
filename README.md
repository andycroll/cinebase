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
it cannot get a current token. `GuestToken.expires_at(token)` reads a token's
`exp` claim as a `Time`, or `nil` when it cannot.

A chain module keeps its token by extending `TokenHolder`:

```ruby
module CinemaChainName
  extend Cinebase::Vista::TokenHolder

  def self.guest_token_class
    Internal::GuestToken
  end
end

CinemaChainName.token = guest_jwt        # set one you already have
CinemaChainName.acquire_token!           # always fetches a new token
CinemaChainName.ensure_token!            # fetches only when there is no token
                                         # or it expires within an hour
CinemaChainName.token_expires_at         #=> 2026-10-30 18:00:00 +0000
CinemaChainName.reject_token!(rejected)  # forgets a token the API rejected
```

API calls never fetch a token themselves. When the API rejects a token, the
chain gem calls `reject_token!` and re-raises, so the next `ensure_token!`
fetches a fresh one. `reject_token!` keeps a token set since the rejected
request. To ship curl-impersonate inside platform gems,
add this to the chain gem's Rakefile:

```ruby
require 'cinebase/vista/package_task'
Cinebase::Vista::PackageTask.new('chain_name.gemspec')
# rake 'package:native[arm64-darwin]' or rake package:all
```

### Boxoffice chains

Chains whose websites run on Webedia's "Movies Pro" theme and sell tickets
through Boxoffice (Everyman, Showcase) share a client and base classes. These
are not loaded by `require 'cinebase'`:

```ruby
require 'cinebase/boxoffice'

module CinemaChainName
  class Cinema < Cinebase::Boxoffice::Cinema
    def self.website
      'https://www.example.co.uk'
    end

    def brand
      'Example'
    end
  end

  class Performance < Cinebase::Boxoffice::Performance
    def self.cinema_class
      Cinema
    end

    def self.title_sanitizer
      Internal::TitleSanitizer
    end

    # Optional: the chain's own tags, e.g. screen brands
    def self.variants
      super.merge('Internal.Brand.XPlus' => 'xplus')
    end
  end
end

CinemaChainName::Cinema.all                 # open UK theatres, cached for an hour
CinemaChainName::Performance.at('X0712', from: Date.today, to: Date.today + 365)
```

`Cinema` gives `adr`, `name`, `url`, `latitude`, `longitude` and
`time_zone` from the theatre list in the website's daily build.
`Performance.at` makes one schedule request for the whole range and one
request per 50 films. `Cinebase::Boxoffice::Client.new(base_url:)` is the
underlying client, with `theaters`, `schedule` and `movies`.

### A1Web chains

Chains whose websites run on Admit One's A1Web (Arc, Reel, Movie House)
share a client, a what's on page parser and base classes. These are not
loaded by `require 'cinebase'`:

```ruby
require 'cinebase/a1web'

module CinemaChainName
  class Cinema < Cinebase::A1web::Cinema
    def self.website
      'https://www.example.co.uk'
    end

    # Optional: A1Web sites publish no structured addresses
    def self.locations
      {
        'EX_HIGH' => {
          street_address: '1 High Street', locality: 'Exampleton', postal_code: 'EX1 1AA',
          latitude: 52.5, longitude: -1.25
        }
      }
    end

    def brand
      'Example'
    end
  end

  class Performance < Cinebase::A1web::Performance
    def self.cinema_class
      Cinema
    end

    def self.title_sanitizer
      Internal::TitleSanitizer
    end

    # Optional: the chain's own showtime icons and headings
    def self.variants
      super.merge('Hypersense' => 'hypersense')
    end
  end
end

CinemaChainName::Cinema.all                 # venues in the cinema menu, cached for an hour
CinemaChainName::Performance.at('EX_HIGH', from: Date.today, to: Date.today + 365)
```

Cinema ids are A1Web site codes such as `ARC_BEE`. The home page's
`GlobalSiteData` lists them, and where it does not, each venue's own page
sets one. `Performance.at` makes one request: the venue's `/whatson` page
holds every advertised date. `Cinebase::A1web::Listings` reads all three
known templates, whose date panels are keyed by timestamp (Arc), have a
timestamp on their tab (Movie House) or have only a label such as
`Tue 03 Nov` (Reel). Showtime tags are icon names, `a1-event-*` icon
classes and group headings; `Performance::VARIANTS` maps the shared ones.

## Contributing

1. [Fork it](https://github.com/andycroll/cinebase/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
