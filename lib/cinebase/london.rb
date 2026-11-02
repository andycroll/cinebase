# frozen_string_literal: true

module Cinebase
  # Dates and times in London, where chain websites list showtimes
  module London
    ZONE = 'Europe/London'

    # @return [Date] today's date in London
    def self.today
      zone.now.to_date
    end

    # @param [Time] local a London wall-clock time whose fields are read as
    #   is, whatever its offset
    # @return [Time] the UTC time. A time in the hour repeated when clocks go
    #   back is read as British Summer Time.
    def self.utc(local)
      zone.local_to_utc(local) { |periods| periods.first }.utc
    end

    # @param [Time] time
    # @return [Date] its date in London
    def self.date(time)
      zone.to_local(time).to_date
    end

    # @return [TZInfo::Timezone]
    def self.zone
      TZInfo::Timezone.get(ZONE)
    end
  end
end
