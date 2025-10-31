require_relative '../minitest_helper'
require 'date'

class TestPerformance < Cinebase::Performance
  def self.at(cinema_id)
    cinema_id
  end
end

class PerformanceTest < Minitest::Test
  # Tests for abstract template class

  def test_abstract_class_at_raises_error
    assert_raises(NotImplementedError) { Cinebase::Performance.at(123) }
  end

  # Tests without required hash options

  def test_abstract_class_booking_url_without_options_raises_error
    assert_raises(KeyError) { Cinebase::Performance.new({}).booking_url }
  end

  def test_abstract_class_cinema_id_without_options_raises_error
    assert_raises(KeyError) { Cinebase::Performance.new({}).cinema_id }
  end

  def test_abstract_class_cinema_name_without_options_raises_error
    assert_raises(KeyError) { Cinebase::Performance.new({}).cinema_name }
  end

  def test_abstract_class_dimension_without_options_raises_error
    assert_raises(KeyError) { Cinebase::Performance.new({}).dimension }
  end

  def test_abstract_class_film_name_without_options_raises_error
    assert_raises(KeyError) { Cinebase::Performance.new({}).film_name }
  end

  def test_abstract_class_showing_on_without_options_raises_error
    assert_raises(KeyError) { Cinebase::Performance.new({}).showing_on }
  end

  def test_abstract_class_starting_at_without_options_raises_error
    assert_raises(KeyError) { Cinebase::Performance.new({}).starting_at }
  end

  # Tests with required hash options

  def test_abstract_class_booking_url_returns_nil
    options = {
      cinema_id:   123,
      cinema_name: 'Cinema',
      film_name:   'Film Name',
      starting_at: Time.now
    }
    assert_nil(Cinebase::Performance.new(options).booking_url)
  end

  def test_abstract_class_cinema_id_returns_value
    options = {
      cinema_id:   123,
      cinema_name: 'Cinema',
      film_name:   'Film Name',
      starting_at: Time.now
    }
    assert_equal(123, Cinebase::Performance.new(options).cinema_id)
  end

  def test_abstract_class_cinema_name_returns_value
    options = {
      cinema_id:   123,
      cinema_name: 'Cinema',
      film_name:   'Film Name',
      starting_at: Time.now
    }
    assert_equal('Cinema', Cinebase::Performance.new(options).cinema_name)
  end

  def test_abstract_class_dimension_returns_2d_default
    options = {
      cinema_id:   123,
      cinema_name: 'Cinema',
      film_name:   'Film Name',
      starting_at: Time.now
    }
    assert_equal('2d', Cinebase::Performance.new(options).dimension)
  end

  def test_abstract_class_dimension_with_3d_passed_in
    options = {
      cinema_id:   123,
      dimension:   '3d',
      cinema_name: 'Cinema',
      film_name:   'Film Name',
      starting_at: Time.now
    }
    assert_equal('3d', Cinebase::Performance.new(options).dimension)
  end

  def test_abstract_class_film_name_returns_value
    options = {
      cinema_id:   123,
      cinema_name: 'Cinema',
      film_name:   'Film Name',
      starting_at: Time.now
    }
    assert_equal('Film Name', Cinebase::Performance.new(options).film_name)
  end

  def test_abstract_class_showing_on_with_utc_time_returns_utc_date
    options = {
      cinema_id:   123,
      cinema_name: 'Cinema',
      film_name:   'Film Name',
      starting_at: Time.utc(1979, 9, 12, 0, 15, 0)
    }
    assert_equal(Date.new(1979, 9, 12), Cinebase::Performance.new(options).showing_on)
  end

  def test_abstract_class_showing_on_with_non_utc_time_returns_utc_date
    options = {
      cinema_id:   123,
      cinema_name: 'Cinema',
      film_name:   'Film Name',
      starting_at: Time.new(1979, 9, 12, 0, 30, 0, '+01:00')
    }
    assert_equal(Date.new(1979, 9, 11), Cinebase::Performance.new(options).showing_on)
  end

  def test_abstract_class_starting_at_with_utc_time_returns_utc
    options = {
      cinema_id:   123,
      cinema_name: 'Cinema',
      film_name:   'Film Name',
      starting_at: Time.utc(1979, 9, 12, 7, 0, 0)
    }
    result = Cinebase::Performance.new(options).starting_at
    assert_equal(true, result.utc?)
  end

  def test_abstract_class_starting_at_with_utc_time_returns_value
    starting_time = Time.utc(1979, 9, 12, 7, 0, 0)
    options = {
      cinema_id:   123,
      cinema_name: 'Cinema',
      film_name:   'Film Name',
      starting_at: starting_time
    }
    assert_equal(starting_time, Cinebase::Performance.new(options).starting_at)
  end

  def test_abstract_class_starting_at_with_non_utc_time_returns_utc
    options = {
      cinema_id:   123,
      cinema_name: 'Cinema',
      film_name:   'Film Name',
      starting_at: Time.new(1979, 9, 12, 8, 0, 0, '+01:00')
    }
    result = Cinebase::Performance.new(options).starting_at
    assert_equal(true, result.utc?)
  end

  def test_abstract_class_starting_at_with_non_utc_time_returns_converted_value
    options = {
      cinema_id:   123,
      cinema_name: 'Cinema',
      film_name:   'Film Name',
      starting_at: Time.new(1979, 9, 12, 8, 0, 0, '+01:00')
    }
    assert_equal(Time.utc(1979, 9, 12, 7, 0, 0), Cinebase::Performance.new(options).starting_at)
  end

  def test_abstract_class_variant_returns_empty_array
    options = {
      cinema_id:   123,
      cinema_name: 'Cinema',
      film_name:   'Film Name',
      starting_at: Time.now
    }
    assert_equal([], Cinebase::Performance.new(options).variant)
  end

  def test_abstract_class_variant_with_array_returns_sorted_array
    options = {
      cinema_id:   123,
      cinema_name: 'Cinema',
      film_name:   'Film Name',
      starting_at: Time.now,
      variant:     %w(so here we are)
    }
    assert_equal(%w(are here so we), Cinebase::Performance.new(options).variant)
  end

  def test_abstract_class_variant_with_string_returns_sorted_array
    options = {
      cinema_id:   123,
      cinema_name: 'Cinema',
      film_name:   'Film Name',
      starting_at: Time.now,
      variant:     'so here we are'
    }
    assert_equal(%w(are here so we), Cinebase::Performance.new(options).variant)
  end

  # Tests for implemented subclass

  def test_subclass_at_returns_cinema_id
    assert_equal(123, TestPerformance.at(123))
  end
end
