# frozen_string_literal: true

module Cinebase
  module Boxoffice
    # Reads one Boxoffice showtime: its start, booking link and tags
    class Showtime
      # Boxoffice's own tags and the variants they mean. Chains label them
      # differently, e.g. KidsFriendly is Everyman's Toddler Club. Chains
      # merge in their own tags, such as screen brands.
      VARIANTS = {
        'Format.Projection.35mm' => '35mm',
        'Showtime.Accessibility.AudioDescription' => 'audio_described',
        'Showtime.Accessibility.AutismFriendly' => 'relaxed',
        'Showtime.Accessibility.ClosedCaption' => 'subtitled',
        'Showtime.Accessibility.SensoryFriendly' => 'relaxed',
        'Showtime.Accessibility.Subtitled' => 'subtitled',
        'Showtime.Event.QandAEvent' => 'q&a',
        'Showtime.Event.QandARecorded' => 'q&a',
        'Showtime.Experience.EncoreShow' => 'arts',
        'Showtime.Experience.FamilyFriendly' => 'kids',
        'Showtime.Experience.LiveSatellite' => 'arts',
        'Showtime.Experience.LiveShow' => 'arts',
        'Showtime.Restriction.BabyClub' => 'baby',
        'Showtime.Restriction.KidsFriendly' => 'kids',
        'Showtime.Restriction.LoyaltyOnly' => 'members',
        'Showtime.Restriction.Senior' => 'senior',
        'Showtime.Restriction.SilverScreen' => 'senior'
      }.freeze

      # Format.Projection.3d, or RealD3D alone on Showcase's XPlus RealD 3D
      THREE_D = /\.(RealD)?3d\z/i
      LANGUAGE = /\ALocalization\.Language\.(\w+)\z/

      # @param [Hash] showtime one showtime from the schedule
      # @param [String] time_zone the theatre's, e.g. 'Europe/London'
      # @param [Hash{String => String}] variants tags and the variants they mean
      def initialize(showtime, time_zone:, variants: VARIANTS)
        @showtime = showtime
        @time_zone = time_zone
        @variants = variants
      end

      # Showcase also lists a 'relay' provider, so the chain's own 'default'
      # comes first
      # @return [String, nil] the chain's own booking page
      def booking_url
        ticketing = @showtime.dig('data', 'ticketing') || []
        link = ticketing.find { |entry| entry['provider'] == 'default' } || ticketing.first
        link&.fetch('urls', [])&.first
      end

      # @return [String] '2d' or '3d'
      def dimension
        tags.any? { |tag| tag.match?(THREE_D) } ? '3d' : '2d'
      end

      # @return [String, nil] audio language, e.g. 'Korean'
      def language
        tags.filter_map { |tag| tag[LANGUAGE, 1] }.first
      end

      # startsAt is the theatre's local time, without an offset
      # @return [Time] UTC
      def starting_at
        local = Time.utc(*@showtime.fetch('startsAt').scan(/\d+/).map(&:to_i))
        TZInfo::Timezone.get(@time_zone).local_to_utc(local) { |periods| periods.first }.utc
      end

      # @return [Array<String>]
      def variant
        tags.filter_map { |tag| @variants[tag] }.uniq
      end

      private

      def tags
        @showtime.fetch('tags', [])
      end
    end
  end
end
