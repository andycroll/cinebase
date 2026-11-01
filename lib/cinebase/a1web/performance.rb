# frozen_string_literal: true

module Cinebase
  module A1web
    # Performance base class for an A1Web chain. Subclasses define
    # `.cinema_class` and `.title_sanitizer`, and may override `.variants`.
    class Performance < Cinebase::Performance
      # Showtime icons and group headings shared by A1Web chains, and the
      # variants they mean. Chains merge in their own, such as screen brands.
      VARIANTS = {
        'Event Cinema' => 'arts',
        'IMAX' => 'imax',
        'Kids Club' => 'kids',
        'Parent & Baby' => 'baby',
        'Sensory Screening' => 'relaxed',
        'Silver Screen' => 'senior',
        'Subtitled' => 'subtitled',
        'subtitles' => 'subtitled'
      }.freeze

      # A tag, or the title, as some chains list 3D and IMAX copies as films
      THREE_D = /\b3D\b/i
      IMAX = /\bIMAX\b/i
      LANGUAGE = /\((#{TitleSanitizer::LANGUAGES.join('|')})(?: language)?\)/i
      TIME_ZONE = 'Europe/London'

      # @return [Class] the chain's Cinebase::A1web::Cinema subclass
      def self.cinema_class
        raise NotImplementedError, "#{self} must define .cinema_class"
      end

      # @return [Class] the chain's Cinebase::TitleSanitizer subclass
      def self.title_sanitizer
        raise NotImplementedError, "#{self} must define .title_sanitizer"
      end

      # @return [Hash{String => String}] tags and the variants they mean
      def self.variants
        VARIANTS
      end

      # Performances within an inclusive range of listings days, from the
      # venue's what's on page, which holds every advertised date.
      # @param [String] cinema_id e.g. 'ARC_BEE'
      # @param [Date] from first date (defaults to today in London)
      # @param [Date] to last date (defaults to 13 days after from)
      # @return [Array<Cinebase::A1web::Performance>] instances of the subclass
      def self.at(
        cinema_id,
        from: TZInfo::Timezone.get(TIME_ZONE).now.to_date,
        to: from + 13
      )
        raise ArgumentError, 'to must not precede from' if to < from

        cinema = cinema_class.new(cinema_id)
        if cinema.url.empty?
          []
        else
          today = TZInfo::Timezone.get(TIME_ZONE).now.to_date
          html = cinema_class.client.whats_on(cinema.url)
          showings = Listings.new(html, venue_url: cinema.url, today: today).showings
          performances = showings.select { |showing| (from..to).cover?(showing.date) }.map do |showing|
            new(attributes(showing).merge(cinema_id: cinema.id, cinema_name: cinema.name))
          end
          performances.sort_by(&:starting_at)
        end
      end

      def self.attributes(showing)
        title = showing.title
        {
          booking_url: showing.booking_url,
          dimension: [title, *showing.tags].any? { |text| text.match?(THREE_D) } ? '3d' : '2d',
          festival: Festival.from_title(title, year: showing.date.year),
          film_name: title_sanitizer.new(title).sanitized,
          film_year: TitleSanitizer.film_year(title),
          language: title[LANGUAGE, 1],
          starting_at: showing.starting_at,
          variant: variant(showing)
        }
      end
      private_class_method :attributes

      def self.variant(showing)
        variant = showing.tags.filter_map { |tag| variants[tag] }
        variant << 'imax' if showing.title.match?(IMAX)
        variant.uniq
      end
      private_class_method :variant
    end
  end
end
