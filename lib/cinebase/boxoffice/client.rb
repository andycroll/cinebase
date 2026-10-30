# frozen_string_literal: true

require 'json'
require 'net/http'

module Cinebase
  module Boxoffice
    # Reads theatres from a chain website's static build and listings from
    # the website's own Boxoffice API routes. No token is needed.
    class Client
      API_PATH = '/api/gatsby-source-boxofficeapi/'
      BUILD_URL = %r{https://cms-assets\.webediamovies\.pro/prod/[\w-]+/\d{4}-\d{2}-\d{2}/public/}
      # The theme's theatre list query, tried before the home page's others
      THEATERS_QUERY = '2506275789'
      # The website asks for the same number of films at once
      MOVIES_PER_REQUEST = 50
      # Listings days run from 3am to 3am, like the website's
      DAY_STARTS_AT = 'T03:00:00'
      RETRIES = 2
      TRANSIENT_ERRORS = [
        EOFError, Errno::ECONNRESET, Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout, OpenSSL::SSL::SSLError
      ].freeze

      attr_reader :base_url

      # @param [String] base_url the chain website, e.g. 'https://www.everymancinema.com'
      def initialize(base_url:)
        @base_url = base_url.delete_suffix('/')
      end

      # @return [Array<Hash>] every theatre in the website's daily build
      def theaters
        build_url = current_build_url
        hashes = page_data(build_url, 'page-data/index/page-data.json').fetch('staticQueryHashes')
        hashes.sort_by { |hash| hash == THEATERS_QUERY ? 0 : 1 }.each do |hash|
          theaters = page_data(build_url, "page-data/sq/d/#{hash}.json").dig('data', 'allTheater', 'nodes')
          return theaters if theaters
        end
        raise "No theatre list in #{build_url}"
      end

      # @param [String] theater_id e.g. 'X0712'
      # @param [String] time_zone the theatre's, e.g. 'Europe/London'
      # @param [Date] from first listings day
      # @param [Date] to last listings day
      # @return [Hash{String => Hash{String => Array<Hash>}}] showtimes by
      #   movie id, then by day
      def schedule(theater_id, time_zone:, from:, to:)
        query = {
          'from' => from.iso8601 + DAY_STARTS_AT,
          'to' => (to + 1).iso8601 + DAY_STARTS_AT,
          'theaters' => JSON.generate('id' => theater_id, 'timeZone' => time_zone)
        }
        api('schedule', query).dig(theater_id, 'schedule') || {}
      end

      # @param [Array<String>] ids movie ids
      # @return [Array<Hash>] movies
      def movies(ids)
        ids.uniq.each_slice(MOVIES_PER_REQUEST).flat_map { |slice| api('movies', 'ids' => slice) }
      end

      private

      def api(path, query)
        JSON.parse(get("#{@base_url}#{API_PATH}#{path}?#{URI.encode_www_form(query)}", accept: 'application/json'))
      end

      # The build moves to a new dated path every day, and the home page can
      # still link images from an older one
      def current_build_url
        get(@base_url + '/', accept: 'text/html').scan(BUILD_URL).max || raise("No build path on #{@base_url}")
      end

      def page_data(build_url, path)
        JSON.parse(get(build_url + path, accept: 'application/json'))
      end

      def get(url, accept:)
        uri = URI(url)
        request = Net::HTTP::Get.new(uri)
        request['Accept'] = accept
        attempts = 0
        begin
          response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
            http.request(request)
          end
        rescue *TRANSIENT_ERRORS
          attempts += 1
          raise if attempts > RETRIES

          sleep(attempts)
          retry
        end
        # Omit response bodies from errors, and never follow redirects.
        raise "HTTP error #{response.code} from #{uri.host}" unless response.is_a?(Net::HTTPSuccess)

        response.body
      end
    end
  end
end
