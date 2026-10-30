require_relative '../../minitest_helper'
require 'cinebase/boxoffice'
require 'date'

# Hand-written fixtures in the shape of Boxoffice responses: invented films
# and addresses, never recorded output.
module BoxofficeFixtures
  private

  def read_fixture(name)
    File.read(File.expand_path("../../fixtures/boxoffice/#{name}", __dir__))
  end
end

# A chain built on the base classes, as a chain gem would build it
module ExampleChain
  class Cinema < Cinebase::Boxoffice::Cinema
    class << self
      # Tests swap in a fake
      attr_writer :client

      def client
        @client || super
      end

      def website
        'https://www.example-cinema.com'
      end
    end

    def brand
      'Example'
    end
  end

  class TitleSanitizer < Cinebase::TitleSanitizer
    private

    def remove
      [/\APreview:\s*/] + COMMON_REMOVE
    end

    def replace
      COMMON_REPLACE
    end
  end

  class Performance < Cinebase::Boxoffice::Performance
    def self.cinema_class
      Cinema
    end

    def self.title_sanitizer
      TitleSanitizer
    end

    def self.variants
      super.merge('Internal.Brand.Premium' => 'premium')
    end
  end
end

# Stands in for Cinebase::Boxoffice::Client, recording what it is asked for
class FakeBoxofficeClient
  include BoxofficeFixtures

  attr_reader :movie_requests, :schedule_requests, :theater_requests

  def initialize
    @movie_requests = []
    @schedule_requests = []
    @theater_requests = 0
  end

  def theaters
    @theater_requests += 1
    JSON.parse(read_fixture('theaters.json')).dig('data', 'allTheater', 'nodes')
  end

  def schedule(theater_id, time_zone:, from:, to:)
    @schedule_requests << { theater_id: theater_id, time_zone: time_zone, from: from, to: to }
    JSON.parse(read_fixture('schedule.json')).dig(theater_id, 'schedule') || {}
  end

  def movies(ids)
    @movie_requests << ids
    JSON.parse(read_fixture('movies.json')).select { |movie| ids.include?(movie['id']) }
  end
end
