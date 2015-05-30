# Cinebase

[![](https://img.shields.io/gem/v/cinebase.svg)](http://rubygems.org/gems/cinebase)
[![](https://img.shields.io/travis/andycroll/cinebase.svg)](https://travis-ci.org/andycroll/cinebase)
[![](https://img.shields.io/codeclimate/github/andycroll/cinebase.svg)](https://codeclimate.com/github/andycroll/cinebase)
[![](https://img.shields.io/codeclimate/coverage/github/andycroll/cinebase.svg)](https://codeclimate.com/github/andycroll/cinebase/coverage)
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
  end
end

module CinemaChainName
  class Screening < Cinebase::Screening
    def self.at(cinema_id)
      # parse webpages or apis to get screenings for a cinema
    end
  end
end

module CinemaChainName
  module Internal
    class TitleSanitizer < Cinebase::TitleSanitizer
      private

      def remove
        # []
      end

      def replace
        # { core title regex => replacement text }
      end
    end
  end
end
```

## Contributing

1. [Fork it](https://github.com/andycroll/cinebase/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
