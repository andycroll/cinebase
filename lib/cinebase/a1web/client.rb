# frozen_string_literal: true

require 'cgi/escape'
require 'net/http'

module Cinebase
  module A1web
    # Reads venues and listings pages from an A1Web chain website. No token
    # is needed.
    class Client
      # The cinema menu on every page links each venue's own site
      VENUE = %r{<option[^>]*value="(https?://[^"]+)"[^>]*>([^<]*)</option>}
      SITE_CODES = /GlobalSiteData\['([^']+)'\]\s*=\s*'([^']+)'/
      SITE_CODE = /var sitecode\s*=\s*'([^']+)'/
      # Pages claim ISO-8859-1 but send Windows-1252 dashes and quotes
      LEGACY_ENCODING = Encoding::Windows_1252
      RETRIES = 2
      TRANSIENT_ERRORS = [
        EOFError, Errno::ECONNRESET, Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout, OpenSSL::SSL::SSLError
      ].freeze

      attr_reader :base_url

      # @param [String] base_url the chain website, e.g. 'https://www.arccinema.co.uk'
      def initialize(base_url:)
        @base_url = base_url.delete_suffix('/')
      end

      # Venues in the home page's cinema menu, with the site codes the home
      # page lists. Some chains list none.
      # @return [Array<Hash>] with :url, :name and :code (nil when unlisted)
      def venues
        html = get(@base_url + '/')
        codes = html.scan(SITE_CODES).to_h { |url, code| [url.delete_suffix('/'), code] }
        html.scan(VENUE).map { |url, name| [url.delete_suffix('/'), name] }.uniq(&:first).map do |url, name|
          { url: url, name: CGI.unescapeHTML(name).strip, code: codes[url] }
        end
      end

      # @param [String] venue_url e.g. 'https://moviehouse.co.uk/coleraine'
      # @return [String, nil] the site code the venue's home page sets, e.g. 'MH_COLE'
      def site_code(venue_url)
        get(venue_url)[SITE_CODE, 1]
      end

      # @param [String] venue_url e.g. 'https://beeston.arccinema.co.uk'
      # @return [String] the venue's what's on page, with every advertised date
      def whats_on(venue_url)
        get("#{venue_url.delete_suffix('/')}/whatson")
      end

      private

      def get(url)
        uri = URI(url)
        attempts = 0
        begin
          response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
            http.request(Net::HTTP::Get.new(uri))
          end
        rescue *TRANSIENT_ERRORS
          attempts += 1
          raise if attempts > RETRIES

          sleep(attempts)
          retry
        end
        # Omit response bodies from errors, and never follow redirects.
        raise "HTTP error #{response.code} from #{uri.host}" unless response.is_a?(Net::HTTPSuccess)

        decode(response.body)
      end

      def decode(body)
        utf8 = body.dup.force_encoding(Encoding::UTF_8)
        if utf8.valid_encoding?
          utf8
        else
          body.dup.force_encoding(LEGACY_ENCODING).encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
        end
      end
    end
  end
end
