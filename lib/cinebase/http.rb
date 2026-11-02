# frozen_string_literal: true

require 'json'
require 'net/http'

module Cinebase
  # HTTPS requests for chain gems. Retries dropped connections, never
  # follows redirects and leaves response bodies out of errors, which can
  # be whole HTML pages.
  class Http
    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 30
    RETRIES = 2
    TRANSIENT_ERRORS = [
      EOFError, Errno::ECONNRESET, Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout, OpenSSL::SSL::SSLError
    ].freeze

    # Waits between attempts. Tests stub it.
    # @param [Integer] seconds
    def self.pause(seconds)
      sleep(seconds)
    end

    # @param [Integer] read_timeout seconds to wait for a response
    # @param [Hash] headers sent with every request, e.g. a User-Agent
    # @param [Boolean] keep_alive reuse one connection per host until
    #   {#close}, for chains that need many requests to one slow site
    def initialize(read_timeout: READ_TIMEOUT, headers: {}, keep_alive: false)
      @read_timeout = read_timeout
      @headers = headers
      @keep_alive = keep_alive
      @connections = {}
    end

    # @param [String] url
    # @param [Hash] headers
    # @return [String] the response body as UTF-8
    def get(url, headers: {})
      perform(Net::HTTP::Get.new(URI(url), @headers.merge(headers)))
    end

    # @param [String] url
    # @param [Hash] form fields sent form-encoded
    # @param [Hash, Array] json a body sent as JSON
    # @param [Hash] headers
    # @return [String] the response body as UTF-8
    def post(url, form: nil, json: nil, headers: {})
      request = Net::HTTP::Post.new(URI(url), @headers.merge(headers))
      if json
        request['Content-Type'] = 'application/json'
        request.body = JSON.generate(json)
      else
        request.set_form_data(form || {})
      end
      perform(request)
    end

    # Close kept-alive connections
    # @return [nil]
    def close
      @connections.each_value { |connection| connection.finish if connection.started? }
      @connections.clear
      nil
    end

    private

    def perform(request)
      uri = request.uri
      attempts = 0
      begin
        response = send_request(uri, request)
      rescue *TRANSIENT_ERRORS
        drop(uri)
        attempts += 1
        raise if attempts > RETRIES

        self.class.pause(attempts)
        retry
      end

      if response.is_a?(Net::HTTPSuccess)
        String.new(response.body.to_s, encoding: Encoding::UTF_8)
      else
        raise "HTTP error #{response.code} from #{uri.host}"
      end
    end

    def send_request(uri, request)
      if @keep_alive
        connection(uri).request(request)
      else
        start(uri) { |http| http.request(request) }
      end
    end

    # Net::HTTP's own retries would repeat requests behind ours
    def start(uri, &block)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: OPEN_TIMEOUT,
                                          read_timeout: @read_timeout, max_retries: 0, &block)
    end

    def connection(uri)
      @connections[[uri.host, uri.port]] ||= start(uri)
    end

    def drop(uri)
      connection = @connections.delete([uri.host, uri.port])
      connection.finish if connection&.started?
    rescue IOError
      nil
    end
  end
end
