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
    assert_equal(Cinebase::Festival.new(name: 'UK Jewish Film Festival', year: 2026), festival)
  end

  def test_from_title_with_horror_season
    festival = Cinebase::Festival.from_title('Horror Season 2026 From Dusk Till Dawn (1996)', year: 2027)
    assert_equal(Cinebase::Festival.new(name: 'Horror Season', year: 2026), festival)
  end

  def test_from_title_with_cambridge_film_festival
    festival = Cinebase::Festival.from_title('CFF: Rocket Girl', year: 2026)
    assert_equal(Cinebase::Festival.new(name: 'Cambridge Film Festival', year: 2026), festival)
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

class FestivalPrefixesTest < Minitest::Test
  def test_from_title_with_known_festivals_and_any_year
    {
      'Cinecity 2026: Hamnet' => ['Cinecity', 2026],
      'Cinecity 2027: Hamnet' => ['Cinecity', 2027],
      'NFF 2026: Hamnet' => ['NFF', 2026],
      'NFF 2026 Shorts: British Mix' => ['NFF', 2026],
      'SLA 2026: A Silent Voice' => ['Scotland Loves Anime', 2026],
      'UKJFF 2026: Hamnet' => ['UK Jewish Film Festival', 2026],
      'UKJFF: Hamnet' => ['UK Jewish Film Festival', 2025],
      'IFF 2026: The Sheep Detectives' => ['Into Film Festival', 2026],
      'JFF 2026 : Tell Me Everything' => ['UK Jewish Film Festival', 2026],
      'LDNDOCS 2026: Hamnet' => ['LDNDOCS', 2026],
      'LPFF 2026: Hamnet' => ['London Palestine Film Festival', 2026],
      'London Palestine Film Festival: Hamnet' => ['London Palestine Film Festival', 2025],
      'RFF 2026: 12:08 East of Bucharest' => ['Romanian Film Festival', 2026],
      'Queer East 26: A Useful Ghost' => ['Queer East', 2026],
      'Into Film Festival: Flow' => ['Into Film Festival', 2025],
      'French Film Fest UK: Hamnet' => ['French Film Festival', 2025],
      'Women and the World Festival: Hamnet' => ['Women and the World Festival', 2025],
      'FFF: A Man of His Time' => ['French Film Festival', 2025],
      'FFF26: Coward' => ['French Film Festival', 2026],
      'UK Jewish Film Festival: Hamnet' => ['UK Jewish Film Festival', 2025],
      'Women and the World International Film Festival: Hamnet' => ['Women and the World Festival', 2025],
      'Women and the World: Hamnet' => ['Women and the World Festival', 2025]
    }.each do |title, (name, year)|
      assert_equal(Cinebase::Festival.new(name: name, year: year), Cinebase::Festival.from_title(title, year: 2025), title)
    end
  end

  def test_from_title_with_a_festival_after_the_film
    assert_equal(Cinebase::Festival.new(name: 'NFF', year: 2026), Cinebase::Festival.from_title('Party USA - NFF UK Premier', year: 2026))
  end

  def test_from_title_with_a_festival_in_brackets_after_the_film
    assert_equal(Cinebase::Festival.new(name: 'French Film Festival', year: 2026), Cinebase::Festival.from_title('Coward (French Film Festival)', year: 2026))
  end

  def test_from_title_with_a_local_name_for_a_short_form
    festival = Cinebase::Festival.from_title('NFF Comedy - NFF 2026', year: 2026, names: { 'NFF' => 'Nottingham Film Festival' })
    assert_equal(Cinebase::Festival.new(name: 'Nottingham Film Festival', year: 2026), festival)
  end

  def test_from_title_after_a_dochouse_prefix
    assert_equal(Cinebase::Festival.new(name: 'LDNDOCS', year: 2026), Cinebase::Festival.from_title('DocHouse: LDNDOCS2026: Time And Water', year: 2025))
  end

  def test_from_title_needs_the_festival_name_before_a_separator
    assert_nil(Cinebase::Festival.from_title('Cinecityscapes', year: 2026))
    assert_nil(Cinebase::Festival.from_title('IFFY: The Movie', year: 2026))
  end
end
