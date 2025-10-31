require_relative '../minitest_helper'

class TestCinema < Cinebase::Cinema
  def self.all; []; end
  def brand; 'TestBrand'; end
  def adr
    {
      street_address: 'TestStreetAddress',
      extended_address: 'TestExtendedAddress',
      locality: 'TestLocality',
      region: 'TestRegion',
      postal_code: 'TestPostalCode',
      country_name: 'TestCountryName'
    }
  end
  def name; 'TestName'; end
  def url; 'TestUrl'; end
end

class CinemaTest < Minitest::Test
  # Tests for abstract template class

  def test_abstract_class_all_raises_error
    assert_raises(NotImplementedError) { Cinebase::Cinema.all }
  end

  def test_abstract_class_adr_returns_hash
    result = Cinebase::Cinema.new(123).adr
    assert_instance_of(Hash, result)
  end

  def test_abstract_class_adr_contains_all_requisite_keys
    result = Cinebase::Cinema.new(123).adr
    assert_equal([:street_address, :extended_address, :locality, :region, :postal_code, :country_name], result.keys)
  end

  def test_abstract_class_street_address_returns_empty_string
    assert_equal('', Cinebase::Cinema.new(123).street_address)
  end

  def test_abstract_class_extended_address_returns_empty_string
    assert_equal('', Cinebase::Cinema.new(123).extended_address)
  end

  def test_abstract_class_locality_returns_empty_string
    assert_equal('', Cinebase::Cinema.new(123).locality)
  end

  def test_abstract_class_region_returns_empty_string
    assert_equal('', Cinebase::Cinema.new(123).region)
  end

  def test_abstract_class_postal_code_returns_empty_string
    assert_equal('', Cinebase::Cinema.new(123).postal_code)
  end

  def test_abstract_class_country_name_returns_empty_string
    assert_equal('', Cinebase::Cinema.new(123).country_name)
  end

  def test_abstract_class_id_returns_passed_id
    assert_equal(123, Cinebase::Cinema.new(123).id)
  end

  def test_abstract_class_brand_raises_error
    assert_raises(NotImplementedError) { Cinebase::Cinema.new(123).brand }
  end

  def test_abstract_class_full_name_raises_error
    assert_raises(NotImplementedError) { Cinebase::Cinema.new(123).full_name }
  end

  def test_abstract_class_name_raises_error
    assert_raises(NotImplementedError) { Cinebase::Cinema.new(123).name }
  end

  def test_abstract_class_slug_raises_error
    assert_raises(NotImplementedError) { Cinebase::Cinema.new(123).slug }
  end

  def test_abstract_class_url_raises_error
    assert_raises(NotImplementedError) { Cinebase::Cinema.new(123).url }
  end

  # Tests for implemented subclass

  def test_subclass_all_returns_array
    result = TestCinema.all
    assert_instance_of(Array, result)
  end

  def test_subclass_adr_returns_hash
    result = TestCinema.new(123).adr
    assert_instance_of(Hash, result)
  end

  def test_subclass_adr_contains_all_requisite_keys
    result = TestCinema.new(123).adr
    assert_equal([:street_address, :extended_address, :locality, :region, :postal_code, :country_name], result.keys)
  end

  def test_subclass_address_returns_hash
    result = TestCinema.new(123).address
    assert_instance_of(Hash, result)
  end

  def test_subclass_address_contains_all_requisite_keys
    result = TestCinema.new(123).address
    assert_equal([:street_address, :extended_address, :locality, :region, :postal_code, :country_name], result.keys)
  end

  def test_subclass_brand_returns_test_brand
    assert_equal('TestBrand', TestCinema.new(123).brand)
  end

  def test_subclass_country_name_returns_test_country_name
    assert_equal('TestCountryName', TestCinema.new(123).country_name)
  end

  def test_subclass_extended_address_returns_test_extended_address
    assert_equal('TestExtendedAddress', TestCinema.new(123).extended_address)
  end

  def test_subclass_full_name_returns_brand_and_name
    assert_equal('TestBrand TestName', TestCinema.new(123).full_name)
  end

  def test_subclass_locality_returns_test_locality
    assert_equal('TestLocality', TestCinema.new(123).locality)
  end

  def test_subclass_name_returns_test_name
    assert_equal('TestName', TestCinema.new(123).name)
  end

  def test_subclass_postal_code_returns_test_postal_code
    assert_equal('TestPostalCode', TestCinema.new(123).postal_code)
  end

  def test_subclass_region_returns_test_region
    assert_equal('TestRegion', TestCinema.new(123).region)
  end

  def test_subclass_slug_returns_slugified_name
    assert_equal('testbrand-testname', TestCinema.new(123).slug)
  end

  def test_subclass_street_address_returns_test_street_address
    assert_equal('TestStreetAddress', TestCinema.new(123).street_address)
  end

  def test_subclass_url_returns_test_url
    assert_equal('TestUrl', TestCinema.new(123).url)
  end
end
