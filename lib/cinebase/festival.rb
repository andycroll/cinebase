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

    # Title prefixes naming a festival: the name, then the year when given
    PREFIXES = [
      /\A(Cine-Excess) (20\d{2}): /,
      /\A(Cinemagic) (\d{4}) -/,
      /\A(Horror Season) (20\d{2}) /,
      /\A(#{NAMES.map { |name| Regexp.escape(name) }.join('|')})(?: ((?:20)?\d{2}))?\s*[:–-]\s*/
    ].freeze

    CENTURY = 2000

    # @param [String] title raw film title
    # @param [Integer] year the edition when the title gives none, usually the
    #   screening's year
    # @return [Cinebase::Festival, nil]
    def self.from_title(title, year:)
      PREFIXES.each do |prefix|
        match = title.match(prefix)
        return new(name: match[1], year: edition(match[2]) || year) if match
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
