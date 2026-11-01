require_relative 'example_chain'

class A1webPerformanceTest < Minitest::Test
  DATE = Date.new(2026, 11, 1)

  def setup
    @client = FakeA1webClient.new
    ExampleA1webChain::Cinema.client = @client
    ExampleA1webChain::Cinema.instance_variable_set(:@venues_hash, nil)
  end

  def teardown
    ExampleA1webChain::Cinema.client = nil
  end

  def test_hooks_must_be_defined
    assert_raises(NotImplementedError) { Cinebase::A1web::Performance.cinema_class }
    assert_raises(NotImplementedError) { Cinebase::A1web::Performance.title_sanitizer }
    assert_equal Cinebase::A1web::Performance::VARIANTS, Cinebase::A1web::Performance.variants
  end

  def test_at_returns_performances_of_the_subclass_in_time_order
    performances = performances_at('EX_HIGH')

    assert(performances.all? { |p| p.instance_of?(ExampleA1webChain::Performance) })
    assert_equal 5, performances.count
    assert_equal performances.map(&:starting_at).sort, performances.map(&:starting_at)
  end

  def test_at_reads_one_page_for_every_date
    performances_at('ex_high')

    assert_equal ['https://high-street.example-cinema.co.uk'], @client.whats_on_requests
  end

  def test_at_keeps_to_the_range
    performances = ExampleA1webChain::Performance.at('EX_HIGH', from: DATE, to: DATE + 13)

    assert_equal 4, performances.count
  end

  def test_at_defaults_to_a_fortnight_from_today
    assert_equal ExampleA1webChain::Performance.at('EX_HIGH').count,
                 ExampleA1webChain::Performance.at('EX_HIGH', from: Date.today, to: Date.today + 13).count
  end

  def test_at_rejects_a_backwards_range
    assert_raises(ArgumentError) { ExampleA1webChain::Performance.at('EX_HIGH', from: DATE, to: DATE - 1) }
  end

  def test_at_an_unknown_cinema_is_empty
    assert_empty performances_at('EX_GONE')
    assert_empty @client.whats_on_requests
  end

  def test_at_sets_cinema_details
    performances = performances_at('EX_HIGH')

    assert_equal ['EX_HIGH'], performances.map(&:cinema_id).uniq
    assert_equal ['High Street'], performances.map(&:cinema_name).uniq
  end

  def test_at_parses_first_performance
    performance = performances_at('EX_HIGH').first

    assert_equal 'The Example Film', performance.film_name
    assert_nil performance.film_year
    assert_equal Time.utc(2026, 11, 1, 10, 30), performance.starting_at
    assert_equal '2d', performance.dimension
    assert_nil performance.language
    assert_nil performance.festival
    assert_equal %w(baby), performance.variant
    assert_equal 'https://high-street.example-tickets.co.uk/tickets/?perfCode=5002', performance.booking_url
  end

  def test_chain_variants_merge_with_shared_ones
    variants = performances_at('EX_HIGH').map(&:variant)

    assert_equal [%w(baby), %w(premium), [], %w(subtitled), %w(arts)], variants
  end

  def test_3d_from_the_icon_with_the_title_sanitized
    performance = performances_at('EX_HIGH').find { |p| p.dimension == '3d' }

    assert_equal 'THE EXAMPLE SEQUEL', performance.film_name
  end

  def test_3d_and_imax_from_the_title
    showing = Cinebase::A1web::Showing.new(
      film_id: '1', title: 'An Example 3D IMAX (Hindi)', date: DATE, starting_at: Time.utc(2026, 11, 1, 12),
      booking_url: 'https://example.co.uk/booking/1', tags: []
    )
    attributes = ExampleA1webChain::Performance.send(:attributes, showing)

    assert_equal '3d', attributes[:dimension]
    assert_equal %w(imax), attributes[:variant]
    assert_equal 'Hindi', attributes[:language]
  end

  def test_language_from_a_language_suffix
    performance = performances_at('EX_NEWT').last

    assert_equal 'French', performance.language
  end

  def test_shared_titles_are_standardised
    performance = performances_at('EX_HIGH').last

    assert_equal 'Royal Ballet and Opera: The Royal Ballet – An Example Ballet', performance.film_name
  end

  def test_headings_map_to_variants
    performances = performances_at('EX_NEWT')

    assert_equal [[], %w(subtitled), []], performances.map(&:variant)
  end

  private

  def performances_at(cinema_id)
    ExampleA1webChain::Performance.at(cinema_id, from: DATE, to: DATE + 365)
  end
end
