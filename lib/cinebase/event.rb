# frozen_string_literal: true

module Cinebase
  Event = Data.define(:name)

  # A stage show or exhibition screened in cinemas rather than a film
  class Event
    # Prefixes title sanitizers give these shows, keyed by the series
    PREFIXES = {
      'Met Opera' => /\AMet Opera: /,
      'Royal Ballet and Opera' => /\A(?:Royal Ballet and Opera|The Royal Ballet|The Royal Opera): /,
      'National Theatre Live' => /\A(?:National Theatre Live|National Theatre|NT Live): /,
      'Exhibition on Screen' => /\AExhibition on Screen: /,
      'Bolshoi Ballet' => /\ABolshoi(?: Ballet)?: /,
      'Paris Opera' => /\AParis Opera: /
    }.freeze

    PREFIX = Regexp.union(PREFIXES.values)

    # Live sport, keyed by competition. The fixture keeps the competition in
    # its name, as next year's "England v France" is another match.
    SPORTS = {
      'Six Nations' => /\ASix Nations\b/,
      'World Rugby Nations Championship' => /\AWorld Rugby Nations Championship\b/
    }.freeze

    # @param [String] film_name sanitized film name, e.g. "Met Opera: Tosca"
    # @return [Cinebase::Event, nil]
    def self.from_name(film_name)
      name, = PREFIXES.merge(SPORTS).find { |_, prefix| film_name.match?(prefix) }
      new(name: name) if name
    end

    # @param [String] film_name sanitized film name, e.g. "Met Opera: Tosca"
    # @return [String] the show's own name, e.g. "Tosca"
    def self.strip(film_name)
      film_name.sub(PREFIX, '')
    end

    # @return [String] the screening variant the event adds: arts or sport
    def variant
      if SPORTS.key?(name)
        'sport'
      else
        'arts'
      end
    end
  end
end
