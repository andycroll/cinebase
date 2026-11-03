require_relative '../minitest_helper'

class EventTest < Minitest::Test
  def test_from_name_reads_the_sanitized_prefix
    {
      'Met Opera: Tosca' => 'Met Opera',
      'Royal Ballet and Opera: Tosca' => 'Royal Ballet and Opera',
      'The Royal Ballet: Swan Lake' => 'Royal Ballet and Opera',
      'National Theatre Live: Hay Fever' => 'National Theatre Live',
      'National Theatre: Hay Fever' => 'National Theatre Live',
      'NT Live: Hay Fever' => 'National Theatre Live',
      'Exhibition on Screen: Monet' => 'Exhibition on Screen',
      'Bolshoi: Giselle' => 'Bolshoi Ballet',
      'Bolshoi Ballet: Giselle' => 'Bolshoi Ballet',
      'Paris Opera: Giselle' => 'Paris Opera'
    }.each do |film_name, series|
      assert_equal(Cinebase::Event.new(name: series), Cinebase::Event.from_name(film_name), film_name)
    end
  end

  def test_from_name_reads_a_sport_competition
    {
      'Six Nations 2027 - England v France' => 'Six Nations',
      'World Rugby Nations Championship: England V Japan' => 'World Rugby Nations Championship'
    }.each do |film_name, competition|
      assert_equal(Cinebase::Event.new(name: competition), Cinebase::Event.from_name(film_name), film_name)
    end
  end

  def test_variant_is_sport_for_a_competition_and_arts_otherwise
    assert_equal('sport', Cinebase::Event.new(name: 'Six Nations').variant)
    assert_equal('arts', Cinebase::Event.new(name: 'Met Opera').variant)
  end

  def test_from_name_without_event_returns_nil
    assert_nil(Cinebase::Event.from_name('Metropolis'))
    assert_nil(Cinebase::Event.from_name('The Royal Tenenbaums'))
  end

  def test_strip_leaves_the_show
    assert_equal('Tosca', Cinebase::Event.strip('Met Opera: Tosca'))
    assert_equal('The Royal Tenenbaums', Cinebase::Event.strip('The Royal Tenenbaums'))
    assert_equal('Six Nations 2027 - England v France', Cinebase::Event.strip('Six Nations 2027 - England v France'))
  end
end
