require_relative '../minitest_helper'

class FestivalTest < Minitest::Test
  def test_from_title_with_year_in_title
    festival = Cinebase::Festival.from_title('Cine-Excess 2026: Scum Of The Earth', year: 2027)
    assert_equal(Cinebase::Festival.new(name: 'Cine-Excess', year: 2026), festival)
  end

  def test_from_title_with_cinemagic
    festival = Cinebase::Festival.from_title('Cinemagic 2013 - Echo Planet', year: 2014)
    assert_equal(Cinebase::Festival.new(name: 'Cinemagic', year: 2013), festival)
  end

  def test_from_title_without_year_uses_given_year
    festival = Cinebase::Festival.from_title('UKJFF - From Cable Street To Brick Lane', year: 2026)
    assert_equal(Cinebase::Festival.new(name: 'UKJFF', year: 2026), festival)
  end

  def test_from_title_with_horror_season
    festival = Cinebase::Festival.from_title('Horror Season 2026 From Dusk Till Dawn (1996)', year: 2027)
    assert_equal(Cinebase::Festival.new(name: 'Horror Season', year: 2026), festival)
  end

  def test_from_title_with_cambridge_film_festival
    festival = Cinebase::Festival.from_title('CFF: Rocket Girl', year: 2026)
    assert_equal(Cinebase::Festival.new(name: 'CFF', year: 2026), festival)
  end

  def test_from_title_without_festival_returns_nil
    assert_nil(Cinebase::Festival.from_title('Spider-Man: Brand New Day', year: 2026))
  end

  def test_editions_of_the_same_festival_share_a_name
    editions = [2025, 2026].map { |year| Cinebase::Festival.new(name: 'Cine-Excess', year: year) }
    assert_equal(['Cine-Excess'], editions.map(&:name).uniq)
    refute_equal(editions.first, editions.last)
  end
end
