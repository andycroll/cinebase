module Cinebase
  # Screening base class
  class Screening
    attr_reader :booking_url
    attr_reader :dimension
    attr_reader :cinema_id
    attr_reader :cinema_name
    attr_reader :film_name
    attr_reader :showing_at

    def initialize(options)
      @booking_url = options.fetch(:booking_url, nil)
      @cinema_name = options.fetch(:cinema_name)
      @cinema_id   = options.fetch(:cinema_id)
      @dimension   = options.fetch(:dimension, '2d')
      @film_name   = options.fetch(:film_name)
      @showing_at  = options.fetch(:time)
      @variant     = options.fetch(:variant, [])
    end

    # Implement to deliver an Array of Screening objects
    def self.at(cinema_id)
      fail NotImplementedError, "This #{self.class} cannot respond to: "
    end

    def showing_on
      @showing_at.to_date
    end

    def variant
      @variant = @variant.split(' ') if @variant.is_a?(String)
      @variant.map(&:downcase).sort.uniq
    end
  end
end
