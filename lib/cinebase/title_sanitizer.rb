# frozen_string_literal: true

module Cinebase
  # Sabitize titles base class
  TitleSanitizer = Struct.new(:title) do
    def sanitized
      @sanitized ||= begin
        sanitized = title.dup
        remove.each do |pattern|
          sanitized.gsub! pattern, ''
        end
        replace.each do |pattern, prefix|
          sanitized.gsub!(pattern) { |_| prefix + $1 }
        end
        sanitized.squeeze(' ').strip
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
  # Rules every chain can share; subclasses opt in, e.g.
  # `COMMON_REMOVE + [...]` in #remove
  class TitleSanitizer
    LANGUAGES = %w(Arabic Cantonese French Hindi Kannada Korean Malayalam
                   Mandarin Marathi Polish Punjabi Tamil Telugu Turkish).freeze

    COMMON_REMOVE = [
      *Festival::PREFIXES,                              # festival prefix
      /\s+[23]d\b/i,                                    # dimension
      /\((#{LANGUAGES.join('|')})\)/i,                  # language version
      /\((Dubbed|Subbed|English Dub|[^)]*subtitles)\)/i, # dub or subtitle version
      /\(\d+(st|nd|rd|th) Anniversary\)/i,              # anniversary re-release
      /\s*\+\s*(In-Person )?Q&A\z/i,                    # Q&A add-on
      /:\s*Encore\z/i,                                  # encore
      /\bsing-?a-?long\z/i,                             # singalong
      'amp;'                                            # html ampersands
    ].freeze

    COMMON_REPLACE = {
      /Met Opera 20\d{2}-\d{2}: (.*)/              => 'Met Opera: ',
      /RBO (?:Cinema Season )?20\d{2}-\d{2}: (.*)/ => 'Royal Ballet and Opera: ',
      /WORLD TOUR(.*)/                             => 'World Tour'
    }.freeze
  end
end
