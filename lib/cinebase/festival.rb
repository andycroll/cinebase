# frozen_string_literal: true

module Cinebase
  Festival = Data.define(:name, :year)

  # An annual festival edition a film is screened in
  class Festival
    NAMES = [
      'CFF', 'Cinecity', 'FFF', 'French Film Fest UK', 'IFF', 'Into Film Festival', 'JFF', 'LDNDOCS',
      'London Palestine Film Festival', 'LPFF', 'NFF', 'Queer East', 'RFF', 'SLA', 'UKJFF',
      'Women and the World Festival'
    ].freeze

    # Full names for short forms, so every chain names a festival alike
    FULL_NAMES = {
      'CFF' => 'Cambridge Film Festival',
      'FFF' => 'French Film Festival',
      'French Film Fest UK' => 'French Film Festival',
      'IFF' => 'Into Film Festival',
      'JFF' => 'UK Jewish Film Festival',
      'LPFF' => 'London Palestine Film Festival',
      'RFF' => 'Romanian Film Festival',
      'SLA' => 'Scotland Loves Anime',
      'UKJFF' => 'UK Jewish Film Festival'
    }.freeze

    NAME_PATTERN = NAMES.map { |name| Regexp.escape(name) }.join('|')

    # Title prefixes naming a festival: the name, then the year when given
    PREFIXES = [
      /\A(Cine-Excess) (20\d{2}): /,
      /\A(Cinemagic) (\d{4}) -/,
      /\A(Horror Season) (20\d{2}) /,
      /\A(#{NAME_PATTERN})(?: ((?:20)?\d{2}))?\s*[:–-]\s*/
    ].freeze

    # A festival named after the film, such as "Party USA - NFF UK Premier"
    SUFFIX = /\s+[-–]\s+(#{NAME_PATTERN})\b(?: ((?:20)?\d{2})\b)?.*\z/

    PATTERNS = [*PREFIXES, SUFFIX].freeze

    CENTURY = 2000

    # @param [String] title raw film title
    # @param [Integer] year the edition when the title gives none, usually the
    #   screening's year
    # @return [Cinebase::Festival, nil]
    def self.from_title(title, year:)
      PATTERNS.each do |pattern|
        match = title.match(pattern)
        return new(name: FULL_NAMES.fetch(match[1], match[1]), year: edition(match[2]) || year) if match
      end
      nil
    end

    # "26" in "Queer East 26:" is 2026
    def self.edition(year)
      return unless year

      year = Integer(year, 10)
      year < 100 ? CENTURY + year : year
    end
    private_class_method :edition
  end
end
