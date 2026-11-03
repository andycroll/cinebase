# frozen_string_literal: true

module Cinebase
  # Screenings for a particular audience, which some chains name in the title
  module Audience
    SEPARATOR = /\s*[-–:]?\s*/

    # Title labels, keyed by the variant they mark
    LABELS = {
      'kids' => [/\A(?:Toddler (?:Club|Kino)|Kids'? Club)\s*:\s*/i],
      'relaxed' => [/\ARelaxed(?: Screening)?\s*:\s*/i, /#{SEPARATOR}(?:Sensory|Autism) Friendly Screening\z/i],
      'dog_friendly' => [/\ADog-Friendly Screening\s*:\s*/i],
      'baby' => [/\s*\(Parent (?:&|and) Baby(?: Only Show)?\)/i],
      'members' => [/#{SEPARATOR}(?:Unlimited|MyOmnipass Member) Screening\z/i],
      'subtitled' => [/\([^)]*\bsubtitles\)/i],
      'preview' => [/\s*[-–]\s*(?:Special )?Preview\z/i, /\ASee It First\s*[-–:]\s*/i]
    }.freeze

    PATTERNS = LABELS.values.flatten.freeze

    # @param [String] title raw film title
    # @return [Array<String>] variants the title's labels mark
    def self.variants(title)
      LABELS.select { |_, patterns| patterns.any? { |pattern| title.match?(pattern) } }.keys
    end
  end
end
