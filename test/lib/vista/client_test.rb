require_relative '../../minitest_helper'
require 'cinebase/vista'
require 'webmock/minitest'

class VistaClientTest < Minitest::Test
  BASE_URL = 'https://vista.example.com/ocapi/v1/'.freeze

  def test_get_sends_token_and_region
    stub_request(:get, "#{BASE_URL}sites")
      .with(headers: { 'Authorization' => 'Bearer guest-jwt', 'Connect-Region-Code' => 'UK' })
      .to_return(status: 200, body: '{"sites":[]}')

    assert_equal({ 'sites' => [] }, client.get('sites'))
  end

  def test_get_without_region_omits_header
    stub_request(:get, "#{BASE_URL}sites")
      .with { |request| !request.headers.key?('Connect-Region-Code') }
      .to_return(status: 200, body: '{"sites":[]}')

    client = Cinebase::Vista::Client.new(base_url: BASE_URL, region_code: nil, token: 'guest-jwt')

    assert_equal({ 'sites' => [] }, client.get('sites'))
  end

  def test_get_repeats_array_query_values
    stub_request(:get, "#{BASE_URL}showtimes/by-business-date/2026-10-24?siteIds=017&siteIds=824")
      .to_return(status: 200, body: '{"showtimes":[]}')

    assert_equal({ 'showtimes' => [] },
                 client.get('showtimes/by-business-date/2026-10-24', 'siteIds' => %w(017 824)))
  end

  def test_get_reuses_one_connection
    stub_request(:get, "#{BASE_URL}sites").to_return(status: 200, body: '{"sites":[]}')
    shared = client
    starts = count_connection_starts { 3.times { shared.get('sites') } }

    assert_equal 1, starts
  end

  def test_concurrent_gets_on_one_client_all_succeed
    stub_request(:get, "#{BASE_URL}sites").to_return(status: 200, body: '{"sites":[]}')
    shared = client

    results = Array.new(4) { Thread.new { shared.get('sites') } }.map(&:value)

    assert_equal [{ 'sites' => [] }] * 4, results
  end

  def test_get_without_token_raises_before_request
    assert_raises(Cinebase::Vista::AuthenticationError) { client(token: nil).get('sites') }
    assert_raises(Cinebase::Vista::AuthenticationError) { client(token: ' ').get('sites') }
  end

  def test_get_with_rejected_token_raises
    stub_request(:get, "#{BASE_URL}sites").to_return(status: 401)

    assert_raises(Cinebase::Vista::AuthenticationError) { client.get('sites') }
  end

  def test_get_with_server_error_omits_body
    stub_request(:get, "#{BASE_URL}sites").to_return(status: 500, body: 'secret')

    error = assert_raises(RuntimeError) { client.get('sites') }
    assert_equal('Vista HTTP error 500', error.message)
  end

  private

  def count_connection_starts
    starts = 0
    counter = Module.new do
      define_method(:start) do |*args, **options, &block|
        starts += 1
        super(*args, **options, &block)
      end
    end
    Net::HTTP.singleton_class.prepend(counter)
    yield
    starts
  ensure
    counter.send(:remove_method, :start)
  end

  def client(token: 'guest-jwt')
    Cinebase::Vista::Client.new(base_url: BASE_URL, region_code: 'UK', token: token)
  end
end
