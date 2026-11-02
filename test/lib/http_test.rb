require_relative '../minitest_helper'
require 'webmock/minitest'

class HttpTest < Minitest::Test
  URL = 'https://www.example-cinema.co.uk/whatson'.freeze

  def test_get_returns_the_body_as_utf_8
    stub_request(:get, URL).to_return(status: 200, body: 'Amélie'.b)

    body = Cinebase::Http.new.get(URL)

    assert_equal Encoding::UTF_8, body.encoding
    assert_equal 'Amélie', body
  end

  def test_get_sends_default_and_request_headers
    stub_request(:get, URL).with(headers: { 'User-Agent' => 'example', 'Accept' => 'application/json' })
                           .to_return(status: 200, body: '{}')

    Cinebase::Http.new(headers: { 'User-Agent' => 'example' }).get(URL, headers: { 'Accept' => 'application/json' })

    assert_requested :get, URL
  end

  def test_post_sends_a_form
    stub_request(:post, URL).with(body: { 'action' => 'filter', 'day' => '2026-11-02' }).to_return(status: 200, body: 'ok')

    assert_equal 'ok', Cinebase::Http.new.post(URL, form: { 'action' => 'filter', 'day' => '2026-11-02' })
  end

  def test_post_sends_json
    stub_request(:post, URL).with(body: '{"query":"{ films }"}', headers: { 'Content-Type' => 'application/json' })
                            .to_return(status: 200, body: '{}')

    assert_equal '{}', Cinebase::Http.new.post(URL, json: { query: '{ films }' })
  end

  def test_errors_name_the_status_and_host_but_not_the_body
    stub_request(:get, URL).to_return(status: 500, body: 'secret')

    error = assert_raises(RuntimeError) { Cinebase::Http.new.get(URL) }

    assert_equal 'HTTP error 500 from www.example-cinema.co.uk', error.message
  end

  def test_redirects_are_not_followed
    stub_request(:get, URL).to_return(status: 301, headers: { 'Location' => 'https://elsewhere.example/' })

    assert_raises(RuntimeError) { Cinebase::Http.new.get(URL) }
    assert_not_requested :get, 'https://elsewhere.example/'
  end

  def test_dropped_connections_are_retried
    stub_request(:get, URL).to_raise(Errno::ECONNRESET).then.to_raise(Net::ReadTimeout).then.to_return(status: 200, body: 'ok')
    pauses = []

    body = Cinebase::Http.stub(:pause, ->(seconds) { pauses << seconds }) { Cinebase::Http.new.get(URL) }

    assert_equal 'ok', body
    assert_equal [1, 2], pauses
  end

  def test_posts_are_retried
    stub_request(:post, URL).to_raise(EOFError).then.to_return(status: 200, body: 'ok')

    body = Cinebase::Http.stub(:pause, nil) { Cinebase::Http.new.post(URL, form: {}) }

    assert_equal 'ok', body
  end

  def test_dropped_connections_are_raised_after_retries
    stub_request(:get, URL).to_raise(Errno::ECONNRESET)

    Cinebase::Http.stub(:pause, nil) do
      assert_raises(Errno::ECONNRESET) { Cinebase::Http.new.get(URL) }
    end
    assert_requested :get, URL, times: 3
  end

  def test_keep_alive_reuses_one_connection_per_host
    stub_request(:get, /example-cinema/).to_return(status: 200, body: 'ok')
    http = Cinebase::Http.new(keep_alive: true)
    starts = 0
    start = Net::HTTP.method(:start)
    counting_start = lambda do |*args, **options, &block|
      starts += 1
      start.call(*args, **options, &block)
    end

    Net::HTTP.stub(:start, counting_start) do
      http.get(URL)
      http.get('https://www.example-cinema.co.uk/coming-soon')
    end
    http.close

    assert_equal 1, starts
  end

  def test_keep_alive_reconnects_after_a_dropped_connection
    stub_request(:get, URL).to_raise(Errno::ECONNRESET).then.to_return(status: 200, body: 'ok')
    http = Cinebase::Http.new(keep_alive: true)

    body = Cinebase::Http.stub(:pause, nil) { http.get(URL) }
    http.close

    assert_equal 'ok', body
  end
end
