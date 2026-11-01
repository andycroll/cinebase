# frozen_string_literal: true

require 'cgi/escape'
require 'date'

module Cinebase
  module A1web
    # Reads every showtime from a venue's what's on page. Templates differ in
    # how they date their panels: Arc keys each panel by its local midnight,
    # Movie House gives that timestamp on the panel's tab, and Reel's tabs
    # give only a label such as 'Today' or 'Tue 03 Nov'.
    class Listings
      PANEL = /<div id="panel_?(\d+)"[^>]*tab-content/
      TAB = %r{<button data-target="(\d+)"([^>]*)>(.*?)</button>}m
      TAB_TIMESTAMP = /value="(\d+)"/
      FILM = %r{<h2[^>]*>\s*<a[^>]*href="[^"]*/event/(\d+)[^"]*"[^>]*>(.*?)</a>}m
      # Group headings, such as 'Subtitled', come before the showtimes they label
      HEADING_OR_SHOWTIME = %r{
        <p\sclass="[^"]*font-semibold[^"]*">([^<]*)</p>
        |
        <a\sclass="[^"]*perfButton[^"]*"\shref="([^"]*)"[^>]*>(.*?)</a>
      }mx
      ICON = /alt="([^"]*)"/
      ICON_SUFFIX = /(?:\A|\s+)icon\z/i
      EVENT_ICON = /class="a1-event-([\w-]+)/
      TIME = /(\d{1,2}):(\d{2})/
      DAY_MONTH = /(\d{1,2}) (#{Date::ABBR_MONTHNAMES.compact.join('|')})/
      # Panel keys this long are timestamps rather than tab numbers
      TIMESTAMP_DIGITS = 9
      TIME_ZONE = 'Europe/London'

      # @param [String] html a what's on page
      # @param [String] venue_url the venue's own site, e.g. 'https://beeston.arccinema.co.uk'
      # @param [Date] today the date in London when the page was fetched
      def initialize(html, venue_url:, today:)
        @html = html
        @venue_url = venue_url
        @today = today
      end

      # Each showtime once, as Reel and Movie House repeat them for small screens
      # @return [Array<Cinebase::A1web::Showing>]
      def showings
        all = @html.split(PANEL).drop(1).each_slice(2).flat_map do |key, panel|
          date = panel_date(key)
          date ? panel_showings(panel, date) : []
        end
        all.uniq(&:booking_url)
      end

      private

      def panel_showings(panel, date)
        panel.split(FILM).drop(1).each_slice(3).flat_map do |film_id, title, markup|
          heading = nil
          markup.to_s.scan(HEADING_OR_SHOWTIME).filter_map do |label, href, button|
            if label
              heading = text(label)
              nil
            elsif (time = text(button).match(TIME))
              Showing.new(film_id: film_id, title: text(title), date: date, starting_at: starting_at(date, time),
                          booking_url: booking_url(href), tags: tags(button, heading))
            end
          end
        end
      end

      def panel_date(key)
        if key.length >= TIMESTAMP_DIGITS
          local_date(key.to_i)
        else
          tab_dates[key]
        end
      end

      def tab_dates
        @tab_dates ||= @html.scan(TAB).to_h do |key, attributes, label|
          timestamp = attributes[TAB_TIMESTAMP, 1]
          [key, timestamp ? local_date(timestamp.to_i) : label_date(text(label))]
        end
      end

      def label_date(label)
        case label
        when /\AToday\z/i then @today
        when /\ATomorrow\z/i then @today + 1
        when DAY_MONTH then next_date(Regexp.last_match(1).to_i, Date::ABBR_MONTHNAMES.index(Regexp.last_match(2)))
        end
      end

      # Labels have no year, so the first such date from today
      def next_date(day, month)
        years = [@today.year, @today.year + 1]
        dates = years.filter_map { |year| Date.new(year, month, day) if Date.valid_date?(year, month, day) }
        dates.find { |date| date >= @today }
      end

      def local_date(timestamp)
        TZInfo::Timezone.get(TIME_ZONE).to_local(Time.at(timestamp).utc).to_date
      end

      def starting_at(date, time)
        local = Time.utc(date.year, date.month, date.day, time[1].to_i, time[2].to_i)
        TZInfo::Timezone.get(TIME_ZONE).local_to_utc(local) { |periods| periods.first }.utc
      end

      # Movie House links leave out the venue's path, and only work with it
      def booking_url(href)
        href = CGI.unescapeHTML(href)
        venue_path = URI(@venue_url).path.delete_suffix('/')
        if href.start_with?('/') && !href.start_with?("#{venue_path}/")
          href = venue_path + href
        end
        URI.join(@venue_url, href).to_s
      end

      def tags(button, heading)
        icons = button.scan(ICON).map { |(alt)| text(alt).sub(ICON_SUFFIX, '') }
        (icons + button.scan(EVENT_ICON).flatten + [heading]).compact.reject(&:empty?)
      end

      def text(html)
        CGI.unescapeHTML(html.gsub(/<[^>]*>/, ' ')).gsub(/\s+/, ' ').strip
      end
    end
  end
end
