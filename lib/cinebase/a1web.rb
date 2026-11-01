# frozen_string_literal: true

require 'cinebase'

module Cinebase
  # Shared support for chains whose websites run on Admit One's A1Web, such
  # as Arc, Reel and Movie House. Not loaded by `require 'cinebase'`; these
  # gems `require 'cinebase/a1web'`.
  module A1web
  end
end

require 'cinebase/a1web/client'
require 'cinebase/a1web/showing'
require 'cinebase/a1web/listings'
require 'cinebase/a1web/cinema'
require 'cinebase/a1web/performance'
