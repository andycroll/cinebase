require_relative 'example_chain'
require 'webmock/minitest'

class BoxofficeClientTest < Minitest::Test
  include BoxofficeFixtures

  SITE = 'https://www.example-cinema.com'.freeze
  BUILD = 'https://cms-assets.webediamovies.pro/prod/example-cinema/2026-10-24/public'.freeze
  API = "#{SITE}/api/gatsby-source-boxofficeapi".freeze

  def setup
    stub_request(:get, "#{SITE}/").to_return(status: 200, body: read_fixture('home.html'))
    stub_request(:get, "#{BUILD}/page-data/index/page-data.json")
      .to_return(status: 200, body: read_fixture('page-data-index.json'))
  end

  def test_theaters_from_the_latest_build_on_the_home_page
    known = stub_request(:get, "#{BUILD}/page-data/sq/d/2506275789.json")
            .to_return(status: 200, body: read_fixture('theaters.json'))

    assert_equal %w(X0001 G0002 X99ZZ Y00AA), client.theaters.map { |theater| theater['id'] }
    assert_requested known, times: 1
  end

  def test_theaters_found_in_another_query_when_the_hash_changes
    index = JSON.parse(read_fixture('page-data-index.json')).merge('staticQueryHashes' => %w(1111111111 2222222222))
    stub_request(:get, "#{BUILD}/page-data/index/page-data.json").to_return(status: 200, body: JSON.generate(index))
    stub_request(:get, "#{BUILD}/page-data/sq/d/1111111111.json").to_return(status: 200, body: '{"data":{"site":{}}}')
    stub_request(:get, "#{BUILD}/page-data/sq/d/2222222222.json")
      .to_return(status: 200, body: read_fixture('theaters.json'))

    assert_equal 4, client.theaters.size
  end

  def test_theaters_raise_without_a_theatre_list
    index = JSON.parse(read_fixture('page-data-index.json')).merge('staticQueryHashes' => %w(1111111111))
    stub_request(:get, "#{BUILD}/page-data/index/page-data.json").to_return(status: 200, body: JSON.generate(index))
    stub_request(:get, "#{BUILD}/page-data/sq/d/1111111111.json").to_return(status: 200, body: '{"data":{"site":{}}}')

    error = assert_raises(RuntimeError) { client.theaters }

    assert_equal "No theatre list in #{BUILD}/", error.message
  end

  def test_theaters_raise_without_a_build_path
    stub_request(:get, "#{SITE}/").to_return(status: 200, body: '<html></html>')

    error = assert_raises(RuntimeError) { client.theaters }

    assert_equal "No build path on #{SITE}", error.message
  end

  def test_schedule_asks_for_the_range_from_3am_to_3am
    stub_request(:get, "#{API}/schedule")
      .with(query: {
        'from' => '2026-10-24T03:00:00',
        'to' => '2027-10-25T03:00:00',
        'theaters' => '{"id":"X0001","timeZone":"Europe/London"}'
      })
      .to_return(status: 200, body: read_fixture('schedule.json'))

    schedule = client.schedule('X0001', time_zone: 'Europe/London',
                                        from: Date.new(2026, 10, 24), to: Date.new(2027, 10, 24))

    assert_equal %w(1001 1002 1003 1004 1005), schedule.keys
  end

  def test_schedule_is_empty_for_a_theatre_with_no_showtimes
    stub_request(:get, "#{API}/schedule").with(query: hash_including({})).to_return(status: 200, body: '{}')

    assert_equal({}, client.schedule('X0001', time_zone: 'Europe/London', from: Date.today, to: Date.today))
  end

  def test_movies_in_batches_of_fifty
    ids = (1..60).map(&:to_s)
    first = stub_request(:get, "#{API}/movies?#{ids.first(50).map { |id| "ids=#{id}" }.join('&')}")
            .with(headers: { 'Accept' => 'application/json' })
            .to_return(status: 200, body: read_fixture('movies.json'))
    second = stub_request(:get, "#{API}/movies?#{ids.last(10).map { |id| "ids=#{id}" }.join('&')}")
             .to_return(status: 200, body: '[]')

    assert_equal 4, client.movies(ids + ['1']).size
    assert_requested first, times: 1
    assert_requested second, times: 1
  end

  def test_retries_dropped_connections
    stub_request(:get, "#{API}/movies?ids=1").to_raise(OpenSSL::SSL::SSLError).then.to_return(status: 200, body: '[]')
    api = client
    api.define_singleton_method(:sleep) { |_seconds| nil }

    assert_equal [], api.movies(['1'])
  end

  def test_gives_up_after_repeated_drops
    stub_request(:get, "#{API}/movies?ids=1").to_raise(EOFError)
    api = client
    api.define_singleton_method(:sleep) { |_seconds| nil }

    assert_raises(EOFError) { api.movies(['1']) }
    assert_requested :get, "#{API}/movies?ids=1", times: Cinebase::Boxoffice::Client::RETRIES + 1
  end

  def test_errors_omit_body
    stub_request(:get, "#{API}/movies?ids=1").to_return(status: 500, body: 'secret')

    error = assert_raises(RuntimeError) { client.movies(['1']) }

    assert_equal 'HTTP error 500 from www.example-cinema.com', error.message
  end

  def test_base_url_drops_a_trailing_slash
    assert_equal SITE, Cinebase::Boxoffice::Client.new(base_url: "#{SITE}/").base_url
  end

  private

  def client
    Cinebase::Boxoffice::Client.new(base_url: SITE)
  end
end
