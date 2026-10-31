require_relative 'example_chain'

class BoxofficePerformanceTest < Minitest::Test
  DATE = Date.new(2026, 10, 24)

  def setup
    @client = FakeBoxofficeClient.new
    ExampleChain::Cinema.client = @client
    ExampleChain::Cinema.instance_variable_set(:@theaters_hash, nil)
  end

  def teardown
    ExampleChain::Cinema.client = nil
  end

  def test_hooks_must_be_defined
    assert_raises(NotImplementedError) { Cinebase::Boxoffice::Performance.cinema_class }
    assert_raises(NotImplementedError) { Cinebase::Boxoffice::Performance.title_sanitizer }
    assert_equal Cinebase::Boxoffice::Showtime::VARIANTS, Cinebase::Boxoffice::Performance.variants
  end

  def test_at_returns_performances_of_the_subclass_in_time_order
    performances = performances_at('X0001')

    assert(performances.all? { |p| p.instance_of?(ExampleChain::Performance) })
    assert_equal 5, performances.count
    assert_equal performances.map(&:starting_at).sort, performances.map(&:starting_at)
  end

  def test_at_accepts_lowercase_id
    assert_equal 5, performances_at('x0001').count
  end

  def test_at_sets_cinema_details
    performances = performances_at('X0001')

    assert_equal ['X0001'], performances.map(&:cinema_id).uniq
    assert_equal ['High Street'], performances.map(&:cinema_name).uniq
  end

  def test_at_asks_once_for_the_whole_range
    ExampleChain::Performance.at('X0001', from: DATE, to: DATE + 365)

    assert_equal [{ theater_id: 'X0001', time_zone: 'Europe/London', from: DATE, to: DATE + 365 }],
                 @client.schedule_requests
    assert_equal [%w(1001 1002 1003 1004 1005)], @client.movie_requests
  end

  def test_at_parses_first_performance
    performance = performances_at('X0001').first

    assert_equal 'The Example Film', performance.film_name
    assert_nil performance.film_year
    assert_equal Time.utc(2026, 10, 24, 13, 0), performance.starting_at
    assert_equal '2d', performance.dimension
    assert_nil performance.language
    assert_equal %w(subtitled), performance.variant
    assert_equal 'https://tickets.example-cinema.com/launch/ticketing/00000000-0000-0000-0000-000000000001',
                 performance.booking_url
  end

  def test_at_reads_year_from_title_only
    performance = find('Imaginary Picture')

    assert_equal 1985, performance.film_year
    assert_equal %w(35mm), performance.variant
  end

  def test_at_uses_the_chains_title_sanitizer_and_variants
    performance = find('Made Up Movie')

    assert_equal '3d', performance.dimension
    assert_equal %w(members premium), performance.variant
    assert_equal Time.utc(2026, 10, 25, 11, 0), performance.starting_at
  end

  def test_at_moves_festival_and_language_from_title
    performance = find('Mystery Matinee')

    assert_equal Cinebase::Festival.new(name: 'CFF', year: 2026), performance.festival
    assert_equal 'Tamil', performance.language
    assert_equal %w(baby), performance.variant
  end

  def test_at_keeps_late_shows_on_the_next_utc_day
    performance = performances_at('X0001').find { |p| p.variant == %w(senior) }

    assert_equal Time.utc(2026, 10, 24, 22, 45), performance.starting_at
  end

  def test_at_skips_showtimes_without_a_film
    refute_includes performances_at('X0001').map(&:starting_at), Time.utc(2026, 10, 25, 20, 0)
  end

  def test_at_is_empty_without_showtimes
    assert_empty ExampleChain::Performance.at('G0002', from: DATE, to: DATE)
  end

  def test_at_rejects_range_ending_before_start
    assert_raises(ArgumentError) { ExampleChain::Performance.at('X0001', from: DATE, to: DATE - 1) }
  end

  private

  def find(film_name)
    performances_at('X0001').find { |performance| performance.film_name == film_name }
  end

  def performances_at(cinema_id)
    ExampleChain::Performance.at(cinema_id, from: DATE, to: DATE + 1)
  end
end
