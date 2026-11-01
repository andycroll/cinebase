require_relative 'example_chain'

class A1webListingsTest < Minitest::Test
  include A1webFixtures

  def test_timestamp_panels_give_the_local_date
    showings = listings('whatson-timestamp-panels.html', 'https://high-street.example-cinema.co.uk')

    assert_equal [Date.new(2026, 11, 1)] * 4 + [Date.new(2027, 4, 22)], showings.map(&:date)
  end

  def test_starting_at_is_utc_in_winter_and_summer
    showings = listings('whatson-timestamp-panels.html', 'https://high-street.example-cinema.co.uk')

    assert_equal Time.utc(2026, 11, 1, 14, 0), showings.first.starting_at
    assert_equal Time.utc(2027, 4, 22, 18, 15), showings.last.starting_at
  end

  def test_reads_the_film_and_absolute_booking_link
    showing = listings('whatson-timestamp-panels.html', 'https://high-street.example-cinema.co.uk').first

    assert_equal '1001', showing.film_id
    assert_equal 'The Example Film', showing.title
    assert_equal 'https://high-street.example-tickets.co.uk/tickets/?perfCode=5001', showing.booking_url
  end

  def test_titles_are_decoded_from_windows_1252
    showing = listings('whatson-timestamp-panels.html', 'https://high-street.example-cinema.co.uk').last

    assert_equal 'RBO 2026-27: The Royal Ballet – An Example Ballet', showing.title
  end

  def test_tags_from_icons_and_event_classes
    tags = listings('whatson-timestamp-panels.html', 'https://high-street.example-cinema.co.uk').map(&:tags)

    assert_equal [['Premium Screen'], ['Parent & Baby'], %w(subtitles wheelchair-none), ['3D'], ['Example Events']],
                 tags
  end

  def test_symbol_key_is_not_a_showing
    showings = listings('whatson-timestamp-panels.html', 'https://high-street.example-cinema.co.uk')

    assert_equal 5, showings.size
  end

  def test_labelled_tabs_infer_the_year_from_today
    showings = listings('whatson-labelled-tabs.html', 'https://riverside.example-cinema.co.uk/riverside')

    assert_equal [Date.new(2026, 12, 29), Date.new(2026, 12, 29), Date.new(2026, 12, 30),
                  Date.new(2026, 12, 31), Date.new(2027, 1, 1)],
                 showings.map(&:date)
  end

  def test_unlabelled_dates_are_skipped
    showings = listings('whatson-labelled-tabs.html', 'https://riverside.example-cinema.co.uk/riverside')

    refute_includes showings.map(&:title), 'A Future Film'
  end

  def test_repeated_showings_are_read_once_with_their_heading
    showings = listings('whatson-labelled-tabs.html', 'https://riverside.example-cinema.co.uk/riverside')

    assert_equal %w(3001 3002 3003 3004 3005), showings.map { |showing| showing.booking_url[%r{booking/(\d+)}, 1] }
    assert_equal [[], ['Movie Madness'], [], ['Event Cinema'], []], showings.map(&:tags)
  end

  def test_venue_path_links_stay_as_they_are
    showing = listings('whatson-labelled-tabs.html', 'https://riverside.example-cinema.co.uk/riverside').first

    assert_equal 'https://riverside.example-cinema.co.uk/riverside/booking/3001/the-example-film', showing.booking_url
  end

  def test_valued_tabs_give_the_local_date
    showings = listings('whatson-valued-tabs.html', 'https://new-town.example-cinema.co.uk/new-town')

    assert_equal [Date.new(2026, 11, 1), Date.new(2026, 11, 1), Date.new(2026, 11, 4)], showings.map(&:date)
  end

  def test_links_without_the_venue_path_gain_it
    showing = listings('whatson-valued-tabs.html', 'https://new-town.example-cinema.co.uk/new-town/').first

    assert_equal 'https://new-town.example-cinema.co.uk/new-town/booking/6001/the-example-film', showing.booking_url
  end

  def test_headings_tag_the_showings_after_them
    showings = listings('whatson-valued-tabs.html', 'https://new-town.example-cinema.co.uk/new-town')

    assert_equal [['Film Performance'], ['Subtitled'], ['Film Performance']], showings.map(&:tags)
  end

  def test_buttons_without_a_time_are_skipped
    showings = listings('whatson-valued-tabs.html', 'https://new-town.example-cinema.co.uk/new-town')

    refute(showings.any? { |showing| showing.booking_url.include?('/booking/6002/') })
  end

  def test_a_label_for_29_february_finds_the_next_leap_year
    html = <<~HTML
      <button data-target="0" class="tab">Tue 29 Feb</button>
      <div id="panel0" class="panel-0 tab-content">
        <h2><a href="/event/1/a-film">A Film</a></h2>
        <a class="block perfButton" href="/booking/1/a-film">12:00</a>
      </div>
    HTML
    showings = Cinebase::A1web::Listings.new(html, venue_url: 'https://example.co.uk', today: Date.new(2027, 12, 1))
                                        .showings

    assert_equal [Date.new(2028, 2, 29)], showings.map(&:date)
  end

  def test_a_page_without_panels_has_no_showings
    assert_empty Cinebase::A1web::Listings.new('<html></html>', venue_url: 'https://example.co.uk', today: Date.today)
                                          .showings
  end

  private

  def listings(name, venue_url)
    html = read_fixture(name).force_encoding(Encoding::Windows_1252).encode(Encoding::UTF_8)
    Cinebase::A1web::Listings.new(html, venue_url: venue_url, today: Date.new(2026, 12, 29)).showings
  end
end
