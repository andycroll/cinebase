# frozen_string_literal: true

require 'json'
require 'net/http'

module Cinebase
  module Vista
    # Makes guest-token GET requests to a chain's OCAPI
    class Client
      # @param [String] base_url e.g. 'https://vwc.odeon.co.uk/WSVistaWebClient/ocapi/v1/'
      # @param [String] region_code Connect-Region-Code header, e.g. 'UK' or 'GB'
      # @param [String, nil] token raw guest JWT, without the "Bearer " prefix
      def initialize(base_url:, region_code:, token:)
        @base_url = base_url
        @region_code = region_code
        @token = token
      end

      # @param [String] path relative to the base URL
      # @param [Hash] query parameters; Array values repeat the key
      # @return [Hash] parsed JSON
      # @raise [Cinebase::Vista::AuthenticationError] missing or rejected token
      def get(path, query = {})
        if !@token.is_a?(String) || @token.strip.empty?
          raise AuthenticationError, 'Set a current guest token before fetching data'
        end

        response = request(path, query)
        case response
        when Net::HTTPSuccess
          JSON.parse(response.body)
        when Net::HTTPUnauthorized
          raise AuthenticationError, 'Vista rejected the guest token; supply a fresh one'
        else
          # Omit response bodies and never redirect credentials to another host.
          raise "Vista HTTP error #{response.code}"
        end
      end

      private

      def request(path, query)
        uri = URI(@base_url + path)
        uri.query = URI.encode_www_form(query) unless query.empty?
        request = Net::HTTP::Get.new(uri)
        request['Authorization'] = "Bearer #{@token}"
        request['Connect-Region-Code'] = @region_code
        request['Accept'] = 'application/json'
        Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
          http.request(request)
        end
      end
    end
  end
end
