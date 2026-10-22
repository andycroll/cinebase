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

class CommonSanitizer < Cinebase::TitleSanitizer
  private

  def remove
    COMMON_REMOVE
  end

  def replace
    COMMON_REPLACE
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

  # Tests for the common rules

  def test_common_rules_remove_festival_prefix
    assert_common_sanitized('Scum Of The Earth', 'Cine-Excess 2026: Scum Of The Earth')
  end

  def test_common_rules_remove_dimension
    assert_common_sanitized('Iron Man 3', 'Iron Man 3 3D')
  end

  def test_common_rules_remove_language_version
    assert_common_sanitized('Jailer 2', 'Jailer 2 (Telugu)')
  end

  def test_common_rules_remove_dub_and_sub_versions
    assert_common_sanitized('Arrietty', 'Arrietty (Dubbed)')
    assert_common_sanitized('Arrietty', 'Arrietty (Subbed)')
    assert_common_sanitized('Kung Fu Soccer', 'Kung Fu Soccer (English Dub)')
    assert_common_sanitized('Kung Fu Soccer', 'Kung Fu Soccer (Mandarin with EN/CH subtitles)')
  end

  def test_common_rules_remove_anniversary
    assert_common_sanitized('SCREAM', 'SCREAM (30th Anniversary)')
  end

  def test_common_rules_remove_q_and_a
    assert_common_sanitized('NAZA', 'NAZA + Q&A')
    assert_common_sanitized("Charlie Shaw's Revenge", "Charlie Shaw's Revenge + In-Person Q&A")
  end

  def test_common_rules_remove_encore
    assert_common_sanitized('Avengers Endgame', 'Avengers Endgame: Encore')
  end

  def test_common_rules_remove_trailing_singalong_only
    assert_common_sanitized('Frozen', 'Frozen Sing-a-long')
    assert_common_sanitized('Bebefinn Sing-Along Movie', 'Bebefinn Sing-Along Movie')
  end

  def test_common_rules_fix_html_ampersands
    assert_common_sanitized('Fast & Furious 7', 'Fast &amp; Furious 7')
  end

  def test_common_rules_standardise_arts_seasons
    assert_common_sanitized('Met Opera: Tosca', 'Met Opera 2026-27: Tosca')
    assert_common_sanitized('Royal Ballet and Opera: Manon', 'RBO Cinema Season 2026-27: Manon')
    assert_common_sanitized('Royal Ballet and Opera: Alice', 'RBO 2026-27: Alice')
  end

  def test_common_rules_decapitalise_world_tour
    assert_common_sanitized("ENHYPEN World Tour 'BLOOD SAGA'", "ENHYPEN WORLD TOUR 'BLOOD SAGA'")
  end

  def test_common_rules_keep_titles_with_their_own_subtitles
    [
      'Harry Potter and the Deathly Hallows: Part 1',
      'Spider-Man: Brand New Day',
      'Hadestown: The Musical',
      'Rammstein - Live in Mexico City',
      'Ozzy & Black Sabbath: Back to the Beginning',
      "BTS 'ARIRANG' IN BUENOS AIRES: LIVE VIEWING",
      '3 Days to Kill'
    ].each { |title| assert_common_sanitized(title, title) }
  end

  private

  def assert_common_sanitized(expected, title)
    assert_equal(expected, CommonSanitizer.new(title).sanitized)
  end
end
