require_relative 'example_chain'

class BoxofficeCinemaTest < Minitest::Test
  def setup
    @client = FakeBoxofficeClient.new
    ExampleChain::Cinema.client = @client
    ExampleChain::Cinema.instance_variable_set(:@theaters_hash, nil)
  end

  def teardown
    ExampleChain::Cinema.client = nil
  end

  def test_client_reads_the_chain_website
    chain = Class.new(Cinebase::Boxoffice::Cinema)
    chain.define_singleton_method(:website) { 'https://www.example-cinema.com/' }

    assert_instance_of Cinebase::Boxoffice::Client, chain.client
    assert_equal 'https://www.example-cinema.com', chain.client.base_url
  end

  def test_website_must_be_defined
    assert_raises(NotImplementedError) { Cinebase::Boxoffice::Cinema.website }
  end

  def test_new_stores_upcase_string_id
    assert_equal 'X0001', ExampleChain::Cinema.new('x0001').id
  end

  def test_all_returns_open_uk_cinemas_of_the_subclass
    cinemas = ExampleChain::Cinema.all

    assert(cinemas.all? { |cinema| cinema.instance_of?(ExampleChain::Cinema) })
    assert_equal %w(X0001 G0002), cinemas.map(&:id)
  end

  def test_name_full_name_and_slug
    cinema = ExampleChain::Cinema.new('X0001')

    assert_equal 'High Street', cinema.name
    assert_equal 'Example High Street', cinema.full_name
    assert_equal 'example-high-street', cinema.slug
  end

  def test_url
    assert_equal 'https://www.example-cinema.com/theaters/x0001-example-high-street',
                 ExampleChain::Cinema.new('X0001').url
  end

  def test_adr
    expected = {
      street_address:   '1 Example Street',
      extended_address: nil,
      locality:         'London',
      region:           nil,
      postal_code:      'W1U 0ZZ',
      country_name:     'United Kingdom'
    }

    assert_equal expected, ExampleChain::Cinema.new('X0001').adr
  end

  def test_postal_code_is_tidied
    assert_equal 'SL7 0ZZ', ExampleChain::Cinema.new('G0002').postal_code
  end

  def test_coordinates
    assert_equal [51.5, -0.15], [ExampleChain::Cinema.new('X0001').latitude, ExampleChain::Cinema.new('X0001').longitude]
    assert_nil ExampleChain::Cinema.new('G0002').latitude
  end

  def test_time_zone
    assert_equal 'Europe/London', ExampleChain::Cinema.new('X0001').time_zone
  end

  def test_unknown_cinema_has_empty_details
    cinema = ExampleChain::Cinema.new('X99ZZ')

    assert_equal '', cinema.name
    assert_nil cinema.latitude
  end

  def test_refetches_theaters_after_an_hour
    2.times { ExampleChain::Cinema.all }
    ExampleChain::Cinema.instance_variable_set(:@fetched_at, -Cinebase::Boxoffice::Cinema::CACHE_SECONDS * 2)
    ExampleChain::Cinema.all

    assert_equal 2, @client.theater_requests
  end
end
