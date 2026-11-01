require_relative 'example_chain'

class A1webCinemaTest < Minitest::Test
  def setup
    @client = FakeA1webClient.new
    ExampleA1webChain::Cinema.client = @client
    ExampleA1webChain::Cinema.instance_variable_set(:@venues_hash, nil)
  end

  def teardown
    ExampleA1webChain::Cinema.client = nil
  end

  def test_client_reads_the_chain_website
    chain = Class.new(Cinebase::A1web::Cinema)
    chain.define_singleton_method(:website) { 'https://www.example-cinema.co.uk/' }

    assert_instance_of Cinebase::A1web::Client, chain.client
    assert_equal 'https://www.example-cinema.co.uk', chain.client.base_url
  end

  def test_hooks
    assert_raises(NotImplementedError) { Cinebase::A1web::Cinema.website }
    assert_equal({}, Cinebase::A1web::Cinema.locations)
  end

  def test_new_stores_upcase_string_id
    assert_equal 'EX_HIGH', ExampleA1webChain::Cinema.new('ex_high').id
  end

  def test_all_returns_venues_of_the_subclass
    cinemas = ExampleA1webChain::Cinema.all

    assert(cinemas.all? { |cinema| cinema.instance_of?(ExampleA1webChain::Cinema) })
    assert_equal %w(EX_HIGH EX_RIVE EX_NEWT), cinemas.map(&:id)
  end

  def test_site_codes_missing_from_the_home_page_come_from_venue_pages
    ExampleA1webChain::Cinema.all

    assert_equal %w(https://new-town.example-cinema.co.uk https://closed.example-cinema.co.uk),
                 @client.site_code_requests
  end

  def test_name_full_name_slug_and_url
    cinema = ExampleA1webChain::Cinema.new('EX_RIVE')

    assert_equal 'Riverside & Quay', cinema.name
    assert_equal 'Example Riverside & Quay', cinema.full_name
    assert_equal 'example-riverside-quay', cinema.slug
    assert_equal 'https://riverside.example-cinema.co.uk', cinema.url
  end

  def test_adr_from_locations
    expected = {
      street_address:   '1 Example Street',
      extended_address: nil,
      locality:         'Exampleton',
      region:           nil,
      postal_code:      'EX1 0ZZ',
      country_name:     'United Kingdom'
    }

    assert_equal expected, ExampleA1webChain::Cinema.new('EX_HIGH').adr
  end

  def test_coordinates_from_locations
    cinema = ExampleA1webChain::Cinema.new('EX_HIGH')

    assert_equal [52.5, -1.25], [cinema.latitude, cinema.longitude]
    assert_nil ExampleA1webChain::Cinema.new('EX_RIVE').latitude
    assert_nil ExampleA1webChain::Cinema.new('EX_RIVE').longitude
  end

  def test_unknown_cinema_has_empty_details
    cinema = ExampleA1webChain::Cinema.new('EX_GONE')

    assert_equal '', cinema.name
    assert_equal '', cinema.url
    assert_nil cinema.adr[:locality]
  end

  def test_refetches_venues_after_an_hour
    2.times { ExampleA1webChain::Cinema.all }
    ExampleA1webChain::Cinema.instance_variable_set(:@fetched_at, -Cinebase::A1web::Cinema::CACHE_SECONDS * 2)
    ExampleA1webChain::Cinema.all

    assert_equal 2, @client.venue_requests
  end
end
