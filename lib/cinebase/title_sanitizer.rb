# frozen_string_literal: true

module Cinebase
  # Sabitize titles base class
  TitleSanitizer = Struct.new(:title) do
    def sanitized
      @sanitized ||= begin
        sanitized = title.gsub(/[[:space:]]/, ' ')
        remove.each do |pattern|
          sanitized.gsub! pattern, ''
        end
        replace.each do |pattern, prefix|
          sanitized.gsub!(pattern) { |_| prefix + $1 }
        end
        sanitized = sanitized.squeeze(' ').strip
        series = sanitized[Event::PREFIX].to_s
        series + title_case(sanitized.delete_prefix(series))
      end
    end

    private

    def remove
      fail NotImplementedError, "This #{self.class} cannot respond to: "
    end

    def replace
      fail NotImplementedError, "This #{self.class} cannot respond to: "
    end
  end
end

module Cinebase
  # Rules every chain can share; subclasses opt in after their own patterns,
  # e.g. `[...] + COMMON_REMOVE` in #remove
  class TitleSanitizer
    LANGUAGES = %w(Arabic Bengali Cantonese French Gujarati Hindi Japanese
                   Kannada Korean Lithuanian Malayalam Mandarin Marathi Polish
                   Punjabi Romanian Tamil Telugu Turkish Vietnamese).freeze

    # A trailing "(1996)", allowing other bracketed markers after it
    FILM_YEAR = /\s*\((1[89]\d{2}|20\d{2})\)(?=(?:\s*\([^)]*\))*\s*\z)/

    COMMON_REMOVE = [
      *Festival::PREFIXES,                              # festival prefix
      *Audience::PATTERNS,                              # audience label
      /\A(?:Opening|Closing|Centrepiece|Documentary)(?: Night)? Gala:\s*/i, # festival gala
      /\A[^:]+?\s+presents:\s*/i,                       # presenter credit
      /\s+[23]d\b/i,                                    # dimension
      /\s*\([23]D\)/i,                                  # bracketed dimension
      /\((#{LANGUAGES.join('|')})\)/i,                  # language version
      /\((Dubbed|Subbed|English Dub(?:bed)?|[^)]*subtitles)\)/i, # dub or subtitle version
      /\s*[(\[]\d+(st|nd|rd|th) Anniversary(?: 4K)?(?: Restoration)?[)\]]/i, # anniversary re-release
      /\s*\(4K(?: Restoration)?\)/i,                    # bracketed 4K restoration
      /\s*\((?:20\d{2} )?Encore\)/i,                    # bracketed encore
      /\s*\(Recorded\)/i,                               # recorded, not live
      /\s+[-–]\s+Live On Stage\z/i,                     # filmed stage show
      /\(Re-release\)/i,                                # re-release
      FILM_YEAR,                                        # film year, see .film_year
      /\s*\+\s*(?:[\w.-]+\s+)*Q(?:&|\+)A\z/i,           # Q&A add-on
      /\s*\((?:with )?[^)]*Q(?:&|\+)A\)/i,              # bracketed Q&A
      /\s*\+\s*Discussion\z/i,                          # discussion add-on
      /\s*\+\s*(?:ScreenTalk|Intro(?:duction)?|Short Film)\z/i, # talk or short add-on
      /\s*\((35|70)mm\)/i,                              # film gauge
      /\s+4K(?: Restoration)?\b/i,                      # 4K restoration
      /\s*[-–]?\s*\d+(?:st|nd|rd|th) Anniversary\z/i,   # trailing anniversary
      /:\s*Encore\z/i,                                  # encore
      /\bsing-?a-?long\z/i,                             # singalong
      'amp;'                                            # html ampersands
    ].freeze

    # @param [String] title raw film title
    # @return [Integer, nil] the film's year from a trailing "(1996)"
    def self.film_year(title)
      title[FILM_YEAR, 1]&.to_i
    end

    ARTS_SEASON = %r{\s*(?:(?:20)?\d{2}[-/]\d{2})?}
    ARTS_SEPARATOR = %r{(?:\s*[:/]\s*|\s+[-–]\s+)}

    # Arts series named the way Event::PREFIXES expects; Met Opera first, as
    # some chains list it inside an RBO season
    COMMON_REPLACE = {
      /\A(?:RBO[^:]*:\s*)?(?:The )?Met\.?(?: Opera)?(?:\s+(?:Live|Encore))?#{ARTS_SEASON}#{ARTS_SEPARATOR}(.*)/i =>
        'Met Opera: ',
      /\A(?:RBO|Royal Ballet (?:and|&) Opera|(?:The )?Royal (?:Ballet|Opera))(?:\s+(?:Live|Encore|Cinema Season))?#{ARTS_SEASON}#{ARTS_SEPARATOR}(?:The Royal (?:Ballet|Opera)\s+[-–]\s+)?(.*)/i =>
        'Royal Ballet and Opera: ',
      /\A(?:NT (?:Live|Encore)(?: Encore)?|NTL|National Theatre(?: Live)?)#{ARTS_SEPARATOR}(.*)/i => 'National Theatre Live: ',
      /\AExhibition on Screen#{ARTS_SEPARATOR}(.*)/i => 'Exhibition on Screen: ',
      /\ABolshoi(?: Ballet)?#{ARTS_SEPARATOR}(.*)/i => 'Bolshoi Ballet: ',
      /WORLD TOUR(.*)/ => 'World Tour'
    }.freeze

    SMALL_WORDS = %w(a an and as at but by for from in into nor of on or the to v vs with).freeze
    HONORIFICS = %w(dr mr mrs ms st).freeze
    ROMAN_NUMERAL = /\A(?=[IVX])X{0,3}(?:IX|IV|V?I{0,3})\z/
    VOWEL = /[AEIOUYÀ-Ý]/
    OPENS_PHRASE = /[:\-–]\z/

    private

    # A title listed in capitals, such as "ROCKY IV", reads "Rocky IV"
    def title_case(text)
      if text.match?(/\p{Ll}/)
        text
      else
        words = text.split(' ')
        words.each_with_index.map do |word, index|
          title_case_word(word, opens_phrase: index.zero? || words[index - 1].match?(OPENS_PHRASE))
        end.join(' ')
      end
    end

    # Acronyms such as "BTS", numerals and words with digits keep capitals
    def title_case_word(word, opens_phrase:)
      letters = word.gsub(/\P{L}/, '').downcase
      if word.match?(/\d/) || word.match?(ROMAN_NUMERAL)
        word
      elsif !opens_phrase && SMALL_WORDS.include?(letters)
        word.downcase
      elsif !word.match?(VOWEL) && !HONORIFICS.include?(letters)
        word
      else
        word.split('-').map { |part| part.downcase.sub(/\p{L}/, &:upcase) }.join('-')
      end
    end
  end
end
