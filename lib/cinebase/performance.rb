module Cinebase
  # Performance base class
  class Performance
    attr_reader :booking_url
    attr_reader :dimension
    attr_reader :cinema_id
    attr_reader :cinema_name
    attr_reader :film_name

    def initialize(options)
      @booking_url = options.fetch(:booking_url, nil)
      @cinema_name = options.fetch(:cinema_name)
      @cinema_id   = options.fetch(:cinema_id)
      @dimension   = options.fetch(:dimension, '2d')
      @film_name   = options.fetch(:film_name)
      @time        = options.fetch(:starting_at)
      @variant     = options.fetch(:variant, [])
    end

    # Implement to deliver an Array of Screening objects
    def self.at(cinema_id)
      fail NotImplementedError, "This #{self.class} cannot respond to: "
    end

    def starting_at
      @starting_at ||=
        if @time.utc?
          @time
        else
          TZInfo::Timezone.get('Europe/London').local_to_utc(@time)
        end
    end

    def showing_on
      starting_at.to_date
    end

    def variant
      @variant = @variant.split(' ') if @variant.is_a?(String)
      @variant.map(&:downcase).sort.uniq
    end
  end
end
