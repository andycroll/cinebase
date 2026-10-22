# frozen_string_literal: true

module Cinebase
  Festival = Data.define(:name, :year)

  # An annual festival edition a film is screened in
  class Festival
    # Title prefixes naming a festival: the name, then the year when given
    PREFIXES = [
      /\A(Cine-Excess) (20\d{2}): /,
      /\A(Cinemagic) (\d{4}) -/,
      /\A(UKJFF) -/,
      /\A(CFF): /,
      /\A(Horror Season) (20\d{2}) /
    ].freeze

    # @param [String] title raw film title
    # @param [Integer] year the edition when the title gives none, usually the
    #   screening's year
    # @return [Cinebase::Festival, nil]
    def self.from_title(title, year:)
      PREFIXES.each do |prefix|
        match = title.match(prefix)
        return new(name: match[1], year: Integer(match[2] || year)) if match
      end
      nil
    end
  end
end
