# frozen_string_literal: true

module Cinebase
  module A1web
    # Cinema base class for an A1Web chain. Subclasses define `.website` and
    # `#brand`, and may define `.locations` with addresses and coordinates,
    # which A1Web sites do not publish in a structured form.
    class Cinema < Cinebase::Cinema
      # Worker processes outlive a day's listings, so refetch the venue list
      CACHE_SECONDS = 3600
      ADDRESS_PARTS = %i(street_address extended_address locality region postal_code).freeze

      # @return [String] the chain website, e.g. 'https://www.arccinema.co.uk'
      def self.website
        raise NotImplementedError, "#{self} must define .website"
      end

      # @return [Cinebase::A1web::Client]
      def self.client
        Client.new(base_url: website)
      end

      # @return [Hash{String => Hash}] by site code: :street_address,
      #   :extended_address, :locality, :region, :postal_code, :latitude and
      #   :longitude, each optional
      def self.locations
        {}
      end

      # Every venue in the website's cinema menu
      # @return [Array<Cinebase::A1web::Cinema>] instances of the subclass
      def self.all
        venues_hash.keys.map { |id| new(id) }
      end

      # @param [String] id the A1Web site code, e.g. 'ARC_BEE' or 'arc_bee'
      def initialize(id)
        @id = id.to_s.upcase
      end

      # @return [Hash] contains :street_address, :extended_address,
      #   :locality, :region, :postal_code, :country_name
      def adr
        ADDRESS_PARTS.to_h { |part| [part, location[part]] }.merge(country_name: 'United Kingdom')
      end

      # @return [Float, nil]
      def latitude
        location[:latitude]
      end

      # @return [Float, nil]
      def longitude
        location[:longitude]
      end

      # @return [String] e.g. 'Beeston'
      def name
        venue[:name].to_s
      end

      # @return [String] the venue's own site, e.g. 'https://beeston.arccinema.co.uk'
      def url
        venue[:url].to_s
      end

      # Chains that list no site codes on their home page set one on each
      # venue's own page
      def self.venues_hash
        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        if @venues_hash.nil? || now - @fetched_at > CACHE_SECONDS
          @fetched_at = now
          api = client
          @venues_hash = api.venues.filter_map do |venue|
            code = venue[:code] || api.site_code(venue[:url])
            [code.upcase, venue] if code
          end.to_h
        end
        @venues_hash
      end
      private_class_method :venues_hash

      private

      def location
        self.class.locations.fetch(id, {})
      end

      def venue
        self.class.send(:venues_hash).fetch(id, {})
      end
    end
  end
end
