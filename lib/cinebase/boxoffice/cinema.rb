# frozen_string_literal: true

module Cinebase
  module Boxoffice
    # Cinema base class for a Boxoffice chain. Subclasses define `.website`
    # and `#brand`.
    class Cinema < Cinebase::Cinema
      # Worker processes outlive a day's listings, so refetch the theatre list
      CACHE_SECONDS = 3600

      # @return [String] the chain website, e.g. 'https://www.everymancinema.com'
      def self.website
        raise NotImplementedError, "#{self} must define .website"
      end

      # @return [Cinebase::Boxoffice::Client]
      def self.client
        Client.new(base_url: website)
      end

      # Every open UK cinema
      # @return [Array<Cinebase::Boxoffice::Cinema>] instances of the subclass
      def self.all
        theaters_hash.keys.map { |id| new(id) }
      end

      # @param [String] id the Boxoffice theatre id, e.g. 'X0712' or 'x0712'
      def initialize(id)
        @id = id.to_s.upcase
      end

      # @return [Hash] contains :street_address, :extended_address,
      #   :locality, :region, :postal_code, :country_name
      def adr
        location = theater.dig('practicalInfo', 'location') || {}
        {
          street_address:   location['address'],
          extended_address: nil,
          locality:         location['city'],
          region:           nil,
          postal_code:      location['zip']&.squeeze(' ')&.upcase,
          country_name:     'United Kingdom'
        }
      end

      # @return [Float, nil]
      def latitude
        theater.dig('practicalInfo', 'coordinates', 'latitude')
      end

      # @return [Float, nil]
      def longitude
        theater.dig('practicalInfo', 'coordinates', 'longitude')
      end

      # @return [String] e.g. 'Baker Street'
      def name
        theater['name'].to_s
      end

      # @return [String] e.g. 'Europe/London'
      def time_zone
        theater.fetch('timeZone', 'Europe/London')
      end

      # @return [String] the cinema's page on the chain website
      def url
        self.class.website + theater['path'].to_s
      end

      def self.theaters_hash
        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        if @theaters_hash.nil? || now - @fetched_at > CACHE_SECONDS
          @fetched_at = now
          @theaters_hash = client.theaters.select { |theater| open_in_uk?(theater) }
                                 .to_h { |theater| [theater.fetch('id'), theater] }
        end
        @theaters_hash
      end
      private_class_method :theaters_hash

      def self.open_in_uk?(theater)
        theater.dig('country', 'iso31661A2') == 'GB' && !theater.dig('practicalInfo', 'closed')
      end
      private_class_method :open_in_uk?

      private

      def theater
        self.class.send(:theaters_hash).fetch(id, {})
      end
    end
  end
end
