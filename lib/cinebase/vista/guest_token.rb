# frozen_string_literal: true

require 'json'
require 'open3'

module Cinebase
  module Vista
    # Retrieves a chain website's public guest token with curl-impersonate,
    # without running a browser. Subclasses set PAGE_URL and implement
    # #extract_token(html) and #bundled_curl.
    class GuestToken
      # @param [String, nil] curl curl-impersonate executable; defaults to the
      #   one bundled in the chain gem, then the one on PATH
      def initialize(curl: nil)
        @curl = curl || default_curl
      end

      # @return [String] the guest JWT
      # @raise [Cinebase::Vista::AuthenticationError]
      def fetch
        token = extract_token(request_page)
        unless token.is_a?(String) && !token.empty?
          raise AuthenticationError, 'Guest token is missing from the page'
        end
        validate_expiry!(token)
        token
      rescue JSON::ParserError, ArgumentError, IndexError, TypeError, NoMethodError
        raise AuthenticationError, 'Guest token page data is missing or invalid', cause: nil
      end

      private

      # HTTP statuses whose page still carries the token
      def accepted_statuses
        %w[200]
      end

      def bundled_curl
        nil
      end

      def default_curl
        bundled_curl && File.executable?(bundled_curl) ? bundled_curl : 'curl-impersonate'
      end

      def curl_command
        [@curl, '--disable', '--impersonate', 'chrome150',
         '--compressed', '--silent', '--show-error',
         '--connect-timeout', '10', '--max-time', '30',
         '--write-out', "\n%{http_code}", self.class::PAGE_URL]
      end

      def request_page
        output, _stderr, result = Open3.capture3(*curl_command)
        unless result.success?
          raise AuthenticationError, "Guest token request failed (curl exit #{result.exitstatus})"
        end

        html, _, status = output.rpartition("\n")
        unless accepted_statuses.include?(status)
          raise AuthenticationError, "Guest token page returned HTTP #{status}"
        end
        html
      rescue Errno::ENOENT
        raise AuthenticationError, 'Install curl-impersonate or pass its executable path with curl:'
      end

      def validate_expiry!(token)
        payload = token.split('.').fetch(1).tr('-_', '+/').unpack1('m')
        claims = JSON.parse(payload)
        if Integer(claims.fetch('exp')) <= Time.now.to_i
          raise AuthenticationError, 'Guest token supplied by the page has expired'
        end
      end
    end
  end
end
