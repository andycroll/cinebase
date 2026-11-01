require_relative 'example_chain'
require 'webmock/minitest'

class A1webClientTest < Minitest::Test
  include A1webFixtures

  SITE = 'https://www.example-cinema.co.uk'.freeze
  VENUE = 'https://high-street.example-cinema.co.uk'.freeze

  def test_venues_from_the_cinema_menu_with_listed_site_codes
    stub_request(:get, "#{SITE}/").to_return(status: 200, body: read_fixture('home.html'))

    expected = [
      { url: 'https://high-street.example-cinema.co.uk', name: 'High Street', code: 'EX_HIGH' },
      { url: 'https://riverside.example-cinema.co.uk', name: 'Riverside & Quay', code: 'EX_RIVE' },
      { url: 'https://new-town.example-cinema.co.uk', name: 'New Town', code: nil }
    ]

    assert_equal expected, client.venues
  end

  def test_site_code_from_a_venue_page
    stub_request(:get, 'https://new-town.example-cinema.co.uk/').to_return(status: 200, body: read_fixture('venue.html'))

    assert_equal 'EX_NEWT', client.site_code('https://new-town.example-cinema.co.uk/')
  end

  def test_whats_on_decodes_windows_1252
    stub_request(:get, "#{VENUE}/whatson").to_return(status: 200, body: read_fixture('whatson-timestamp-panels.html'))

    html = client.whats_on("#{VENUE}/")

    assert_equal Encoding::UTF_8, html.encoding
    assert_includes html, 'The Royal Ballet – An Example Ballet'
  end

  def test_whats_on_keeps_utf_8
    stub_request(:get, "#{VENUE}/whatson").to_return(status: 200, body: '<h2>Amélie</h2>')

    assert_equal '<h2>Amélie</h2>', client.whats_on(VENUE)
  end

  def test_retries_dropped_connections
    stub_request(:get, "#{VENUE}/whatson").to_raise(EOFError).then.to_return(status: 200, body: 'ok')
    client.define_singleton_method(:sleep) { |_seconds| nil }

    assert_equal 'ok', client.whats_on(VENUE)
  end

  def test_gives_up_after_retries
    stub_request(:get, "#{VENUE}/whatson").to_raise(Errno::ECONNRESET)
    client.define_singleton_method(:sleep) { |_seconds| nil }

    assert_raises(Errno::ECONNRESET) { client.whats_on(VENUE) }
    assert_requested :get, "#{VENUE}/whatson", times: Cinebase::A1web::Client::RETRIES + 1
  end

  def test_raises_on_http_errors_without_the_body
    stub_request(:get, "#{VENUE}/whatson").to_return(status: 404, body: 'secret')

    error = assert_raises(RuntimeError) { client.whats_on(VENUE) }

    assert_equal 'HTTP error 404 from high-street.example-cinema.co.uk', error.message
  end

  def test_does_not_follow_redirects
    stub_request(:get, "#{SITE}/").to_return(status: 301, headers: { 'Location' => 'https://elsewhere.example/' })

    assert_raises(RuntimeError) { client.venues }
  end

  private

  def client
    @client ||= Cinebase::A1web::Client.new(base_url: "#{SITE}/")
  end
end
