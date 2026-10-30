# frozen_string_literal: true

module Cinebase
  module Boxoffice
    # Performance base class for a Boxoffice chain. Subclasses define
    # `.cinema_class` and `.title_sanitizer`, and may override `.variants`.
    class Performance < Cinebase::Performance
      # @return [Class] the chain's Cinebase::Boxoffice::Cinema subclass
      def self.cinema_class
        raise NotImplementedError, "#{self} must define .cinema_class"
      end

      # @return [Class] the chain's Cinebase::TitleSanitizer subclass
      def self.title_sanitizer
        raise NotImplementedError, "#{self} must define .title_sanitizer"
      end

      # @return [Hash{String => String}] Boxoffice tags and the variants they mean
      def self.variants
        Showtime::VARIANTS
      end

      # Performances within an inclusive range of listings days, from one
      # schedule request for the whole range and one request per 50 films.
      # @param [String] cinema_id e.g. 'X0712'
      # @param [Date] from first date (defaults to today in London)
      # @param [Date] to last date (defaults to 13 days after from)
      # @return [Array<Cinebase::Boxoffice::Performance>] instances of the subclass
      def self.at(
        cinema_id,
        from: TZInfo::Timezone.get('Europe/London').now.to_date,
        to: from + 13
      )
        raise ArgumentError, 'to must not precede from' if to < from

        cinema = cinema_class.new(cinema_id)
        client = cinema_class.client
        schedule = client.schedule(cinema.id, time_zone: cinema.time_zone, from: from, to: to)
        movies = client.movies(schedule.keys).to_h { |movie| [movie.fetch('id').to_s, movie] }

        performances = schedule.flat_map do |movie_id, days|
          title = movies.dig(movie_id.to_s, 'title')
          next [] unless title

          days.values.flatten.map do |showtime|
            parsed = Showtime.new(showtime, time_zone: cinema.time_zone, variants: variants)
            new(attributes(parsed, title).merge(cinema_id: cinema.id, cinema_name: cinema.name))
          end
        end
        performances.sort_by(&:starting_at)
      end

      # Release dates are UK releases, so re-releases would get the wrong year;
      # only a year in the title counts.
      def self.attributes(showtime, title)
        starting_at = showtime.starting_at
        {
          booking_url: showtime.booking_url,
          dimension: showtime.dimension,
          festival: Festival.from_title(title, year: starting_at.year),
          film_name: title_sanitizer.new(title).sanitized,
          film_year: TitleSanitizer.film_year(title),
          language: showtime.language || title[/\((#{TitleSanitizer::LANGUAGES.join('|')})\)/i, 1],
          starting_at: starting_at,
          variant: showtime.variant
        }
      end
      private_class_method :attributes
    end
  end
end
