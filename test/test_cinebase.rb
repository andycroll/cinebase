require 'minitest_helper'

class TestCinebase < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Cinebase::VERSION
  end
end
