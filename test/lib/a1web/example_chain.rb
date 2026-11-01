require_relative '../../minitest_helper'
require 'cinebase/a1web'
require 'date'

# Hand-written fixtures in the shapes of A1Web pages: invented films and
# venues, never recorded output. Arc keys date panels by timestamp, Reel
# labels its tabs and Movie House puts a timestamp on each tab.
module A1webFixtures
  private

  def read_fixture(name)
    File.binread(File.expand_path("../../fixtures/a1web/#{name}", __dir__))
  end
end

# A chain built on the base classes, as a chain gem would build it
module ExampleA1webChain
  class Cinema < Cinebase::A1web::Cinema
    LOCATIONS = {
      'EX_HIGH' => {
        street_address: '1 Example Street',
        locality: 'Exampleton',
        postal_code: 'EX1 0ZZ',
        latitude: 52.5,
        longitude: -1.25
      }
    }.freeze

    class << self
      # Tests swap in a fake
      attr_writer :client

      def client
        @client || super
      end

      def locations
        LOCATIONS
      end

      def website
        'https://www.example-cinema.co.uk'
      end
    end

    def brand
      'Example'
    end
  end

  class TitleSanitizer < Cinebase::TitleSanitizer
    private

    def remove
      [/\s+–\s+3D\z/] + COMMON_REMOVE
    end

    def replace
      COMMON_REPLACE
    end
  end

  class Performance < Cinebase::A1web::Performance
    def self.cinema_class
      Cinema
    end

    def self.title_sanitizer
      TitleSanitizer
    end

    def self.variants
      super.merge('Premium Screen' => 'premium', 'Example Events' => 'arts')
    end
  end
end

# Stands in for Cinebase::A1web::Client, recording what it is asked for
class FakeA1webClient
  include A1webFixtures

  PAGES = {
    'https://high-street.example-cinema.co.uk' => 'whatson-timestamp-panels.html',
    'https://riverside.example-cinema.co.uk' => 'whatson-labelled-tabs.html',
    'https://new-town.example-cinema.co.uk' => 'whatson-valued-tabs.html'
  }.freeze

  attr_reader :site_code_requests, :venue_requests, :whats_on_requests

  def initialize
    @site_code_requests = []
    @venue_requests = 0
    @whats_on_requests = []
  end

  def venues
    @venue_requests += 1
    [
      { url: 'https://high-street.example-cinema.co.uk', name: 'High Street', code: 'EX_HIGH' },
      { url: 'https://riverside.example-cinema.co.uk', name: 'Riverside & Quay', code: 'EX_RIVE' },
      { url: 'https://new-town.example-cinema.co.uk', name: 'New Town', code: nil },
      { url: 'https://closed.example-cinema.co.uk', name: 'Closed', code: nil }
    ]
  end

  def site_code(venue_url)
    @site_code_requests << venue_url
    'ex_newt' if venue_url.include?('new-town')
  end

  def whats_on(venue_url)
    @whats_on_requests << venue_url
    read_fixture(PAGES.fetch(venue_url)).force_encoding(Encoding::Windows_1252).encode(Encoding::UTF_8)
  end
end
