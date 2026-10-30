# frozen_string_literal: true

module Cinebase
  module Vista
    # Keeps a chain's guest token. A chain module extends it and defines
    # .guest_token_class. API calls never fetch a token; callers do, with
    # #acquire_token! or #ensure_token!.
    module TokenHolder
      # A token this close to expiry is renewed, so it outlasts a long import
      RENEWAL_MARGIN = 3600

      # @return [String, nil] raw guest JWT, without the "Bearer " prefix.
      #   Never persisted.
      attr_accessor :token

      # Fetches a new guest token, whatever the current one
      # @param [String, nil] curl curl-impersonate executable
      # @return [String] the guest JWT
      # @raise [Cinebase::Vista::AuthenticationError]
      def acquire_token!(curl: nil)
        self.token = guest_token_class.new(curl: curl).fetch
      end

      # Fetches a guest token only when there is none, or the current one is
      # unreadable or expires within RENEWAL_MARGIN
      # @param [String, nil] curl curl-impersonate executable
      # @return [String] the guest JWT
      # @raise [Cinebase::Vista::AuthenticationError]
      def ensure_token!(curl: nil)
        expires_at = token_expires_at
        if expires_at.nil? || expires_at - Time.now <= RENEWAL_MARGIN
          acquire_token!(curl: curl)
        else
          token
        end
      end

      # Forgets a token the API rejected, so the next #ensure_token! fetches
      # one. A token set since the rejected request is kept.
      # @param [String, nil] rejected the token the API rejected
      def reject_token!(rejected = token)
        self.token = nil if token == rejected
      end

      # @return [Time, nil] from the token's exp claim; nil without a
      #   readable token
      def token_expires_at
        GuestToken.expires_at(token) if token
      end

      # @return [Class] the chain's Cinebase::Vista::GuestToken subclass
      def guest_token_class
        raise NotImplementedError, "#{self} must define guest_token_class"
      end
    end
  end
end
