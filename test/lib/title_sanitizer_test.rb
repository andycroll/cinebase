require_relative '../minitest_helper'

class TestSanitizer < Cinebase::TitleSanitizer
  private

  def remove
    [
      'remove',
      /gon./
    ]
  end

  def replace
    {
      /Bolshoi - (.*)/ => 'Bolshoi: '
    }
  end
end

class TitleSanitizerTest < Minitest::Test
  # Tests for abstract template class

  def test_abstract_class_sanitized_raises_not_implemented_error
    assert_raises(NotImplementedError) { Cinebase::TitleSanitizer.new('anything').sanitized }
  end

  # Tests for implemented subclass

  def test_subclass_sanitized_removes_elements_from_title
    result = TestSanitizer.new('title remove one').sanitized
    assert_equal('title one', result)
  end

  def test_subclass_sanitized_replaces_elements_in_title
    result = TestSanitizer.new('Bolshoi - one dance').sanitized
    assert_equal('Bolshoi: one dance', result)
  end
end
