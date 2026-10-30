require_relative 'example_chain'

class BoxofficeShowtimeTest < Minitest::Test
  def test_starting_at_converts_local_time_to_utc
    assert_equal Time.utc(2026, 7, 1, 18, 30), showtime('startsAt' => '2026-07-01T19:30:00').starting_at
    assert_equal Time.utc(2026, 12, 1, 19, 30), showtime('startsAt' => '2026-12-01T19:30:00').starting_at
  end

  def test_starting_at_in_the_repeated_hour_takes_summer_time
    assert_equal Time.utc(2026, 10, 25, 0, 30), showtime('startsAt' => '2026-10-25T01:30:00').starting_at
  end

  def test_starting_at_in_another_time_zone
    shown = Cinebase::Boxoffice::Showtime.new({ 'startsAt' => '2026-07-01T19:30:00' }, time_zone: 'Europe/Paris')

    assert_equal Time.utc(2026, 7, 1, 17, 30), shown.starting_at
  end

  def test_booking_url_prefers_the_default_provider
    ticketing = [
      { 'provider' => 'relay', 'urls' => ['https://relay.example.com/1'] },
      { 'provider' => 'default', 'urls' => ['https://tickets.example.com/1'] }
    ]

    assert_equal 'https://tickets.example.com/1', showtime('data' => { 'ticketing' => ticketing }).booking_url
  end

  def test_booking_url_falls_back_to_any_provider
    ticketing = [{ 'provider' => 'relay', 'urls' => ['https://relay.example.com/1'] }]

    assert_equal 'https://relay.example.com/1', showtime('data' => { 'ticketing' => ticketing }).booking_url
  end

  def test_booking_url_without_ticketing
    assert_nil showtime('data' => { 'ticketing' => [] }).booking_url
    assert_nil showtime.booking_url
  end

  def test_dimension
    assert_equal '3d', showtime('tags' => ['Format.Projection.3d']).dimension
    assert_equal '3d', showtime('tags' => ['Format.Projection.3D']).dimension
    assert_equal '2d', showtime('tags' => ['Format.Projection.Digital']).dimension
  end

  def test_variant_ignores_unknown_tags_and_repeats
    tags = %w(
      Auditorium.Comfort.ReservedSeating Showtime.Accessibility.Subtitled
      Showtime.Accessibility.ClosedCaption Showtime.Accessibility.AutismFriendly Internal.Data.AlmostSoldOut
    )

    assert_equal %w(subtitled relaxed), showtime('tags' => tags).variant
  end

  def test_variant_reads_a_chains_own_tags
    variants = Cinebase::Boxoffice::Showtime::VARIANTS.merge('Internal.Brand.XPlus' => 'xplus')
    shown = Cinebase::Boxoffice::Showtime.new(
      { 'startsAt' => '2026-10-24T14:00:00', 'tags' => %w(Internal.Brand.XPlus Showtime.Accessibility.Subtitled) },
      time_zone: 'Europe/London', variants: variants
    )

    assert_equal %w(xplus subtitled), shown.variant
    assert_empty showtime('tags' => %w(Internal.Brand.XPlus)).variant
  end

  def test_language
    assert_equal 'Korean', showtime('tags' => ['Localization.Language.Korean']).language
    assert_nil showtime('tags' => []).language
  end

  private

  def showtime(attributes = {})
    Cinebase::Boxoffice::Showtime.new(
      { 'startsAt' => '2026-10-24T14:00:00', 'tags' => [] }.merge(attributes), time_zone: 'Europe/London'
    )
  end
end
