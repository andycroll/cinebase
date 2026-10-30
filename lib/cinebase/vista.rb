# frozen_string_literal: true

require 'cinebase'

module Cinebase
  # Shared support for chains whose sites run on Vista's OCAPI. Not loaded by
  # `require 'cinebase'`; Vista-based gems `require 'cinebase/vista'`.
  module Vista
    class AuthenticationError < StandardError; end
  end
end

require 'cinebase/vista/client'
require 'cinebase/vista/guest_token'
require 'cinebase/vista/token_holder'
