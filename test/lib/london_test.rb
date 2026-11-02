require_relative '../minitest_helper'

class LondonTest < Minitest::Test
  def test_today_is_the_london_date
    late_evening_in_summer = Time.utc(2026, 7, 1, 23, 30)

    today = Time.stub(:now, late_evening_in_summer) { Cinebase::London.today }

    assert_equal Date.new(2026, 7, 2), today
  end

  def test_utc_reads_summer_times_as_bst
    assert_equal Time.utc(2026, 7, 1, 18, 30), Cinebase::London.utc(Time.utc(2026, 7, 1, 19, 30))
  end

  def test_utc_reads_winter_times_as_gmt
    assert_equal Time.utc(2026, 11, 2, 19, 30), Cinebase::London.utc(Time.utc(2026, 11, 2, 19, 30))
  end

  def test_utc_reads_the_repeated_hour_as_bst
    assert_equal Time.utc(2026, 10, 25, 0, 30), Cinebase::London.utc(Time.utc(2026, 10, 25, 1, 30))
  end

  def test_utc_returns_a_utc_time
    assert_predicate Cinebase::London.utc(Time.utc(2026, 7, 1, 19, 30)), :utc?
  end

  def test_date_is_the_london_date
    assert_equal Date.new(2026, 7, 2), Cinebase::London.date(Time.utc(2026, 7, 1, 23, 30))
  end
end
