# frozen_string_literal: true

module Cinebase
  module A1web
    # One showtime on a what's on page.
    # @!attribute [r] film_id
    #   @return [String] the website's event id, e.g. '110406'
    # @!attribute [r] title
    #   @return [String] the film title as listed
    # @!attribute [r] date
    #   @return [Date] the listings date
    # @!attribute [r] starting_at
    #   @return [Time] UTC
    # @!attribute [r] booking_url
    #   @return [String]
    # @!attribute [r] tags
    #   @return [Array<String>] icon names and group headings, e.g. 'IMAX', 'Subtitled'
    Showing = Data.define(:film_id, :title, :date, :starting_at, :booking_url, :tags)
  end
end
