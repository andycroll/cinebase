# frozen_string_literal: true

require 'cinebase'

module Cinebase
  # Shared support for chains whose websites run on Webedia's "Movies Pro"
  # Gatsby theme and sell tickets through Boxoffice. Not loaded by
  # `require 'cinebase'`; these gems `require 'cinebase/boxoffice'`.
  module Boxoffice
  end
end

require 'cinebase/boxoffice/client'
require 'cinebase/boxoffice/showtime'
require 'cinebase/boxoffice/cinema'
require 'cinebase/boxoffice/performance'
