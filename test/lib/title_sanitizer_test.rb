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
    assert_common_sanitized('Scream', 'SCREAM (30th Anniversary)')
  end

  def test_common_rules_remove_q_and_a
    assert_common_sanitized('Naza', 'NAZA + Q&A')
    assert_common_sanitized("Charlie Shaw's Revenge", "Charlie Shaw's Revenge + In-Person Q&A")
  end

  def test_common_rules_remove_named_q_and_a
    assert_common_sanitized('NOFX: 40 Years', 'NOFX: 40 Years + Zoom Q+A')
    assert_common_sanitized('London Breeze: Miss Jobson', 'London Breeze: Miss Jobson + director Q&A')
    assert_common_sanitized("It's Nice Up North", "It's Nice Up North (20th Anniversary) + Q+A")
  end

  def test_common_rules_remove_discussion
    assert_common_sanitized("Pan's Labyrinth", "Pan's Labyrinth 4K + Discussion")
  end

  def test_common_rules_remove_film_gauge
    assert_common_sanitized('The Odyssey', 'The Odyssey (70mm)')
    assert_common_sanitized('Vertigo', 'Vertigo (35mm)')
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

  def test_common_rules_name_arts_series_as_events_expect_them
    {
      'Met Opera: Tosca' => ['Met Opera 2026-27: Tosca', 'MET Opera 2026-27: Tosca', 'Met Opera Live 2026-27: Tosca',
                             'Met Opera Encore 2026-27: Tosca', 'Met. Encore: Tosca', 'RBO 2026-27: The Met Opera – Tosca',
                             'RBO 2026-27: MET Opera - Tosca'],
      'Royal Ballet and Opera: Tosca' => ['RBO: Tosca', 'RBO 2026-27: Tosca', 'RBO 26-27: Tosca', 'RBO 2026/27: Tosca',
                                          'RBO Live 2026-27: Tosca', 'RBO Encore2026-27:Tosca', 'RBO Cinema Season 26-27: Tosca',
                                          'The Royal Opera: Tosca', 'RBO 2026-27: The Royal Opera – Tosca',
                                          'Royal Ballet and Opera: Tosca', 'Royal Ballet & Opera: Tosca'],
      'National Theatre Live: Hay Fever' => ['NT Live: Hay Fever', 'NT Encore: Hay Fever', 'NT Live/ Hay Fever', 'NTL: Hay Fever',
                                             'National Theatre Live: Hay Fever', 'NATIONAL THEATRE LIVE: Hay Fever'],
      'Exhibition on Screen: Monet' => ['EXHIBITION ON SCREEN: Monet', 'Exhibition On Screen: Monet'],
      'Bolshoi Ballet: Giselle' => ['Bolshoi - Giselle']
    }.each do |expected, titles|
      titles.each { |title| assert_common_sanitized(expected, title) }
    end
  end

  def test_common_rules_keep_titles_near_arts_series_names
    ['Metropolis', 'The Royal Tenenbaums', 'Royal Opera House: Behind the Curtain'].each do |title|
      assert_common_sanitized(title, title)
    end
  end

  def test_shows_in_capitals_are_title_cased_after_the_series
    assert_common_sanitized('Royal Ballet and Opera: Swan Lake', 'Royal Ballet and Opera: SWAN LAKE')
  end

  def test_common_rules_remove_audience_labels
    assert_common_sanitized('The Polar Express', 'Toddler Club: The Polar Express')
    assert_common_sanitized('Wicked', 'Wicked - Sensory Friendly Screening')
    assert_common_sanitized('Wicked', 'Dog-Friendly Screening: Wicked')
    assert_common_sanitized("Pan's Labyrinth", "Dog-Friendly: Pan's Labyrinth")
    assert_common_sanitized('The Trip to the Northern Lights', 'The Trip to the Northern Lights: Preview and Q&A')
    assert_common_sanitized('Shorts: British Mix', 'NFF 2026 Shorts: British Mix')
    assert_common_sanitized('Wicked', 'Wicked (Parent & Baby Only Show)')
    assert_common_sanitized('Wicked', 'Wicked - MyOmnipass Member Screening')
    assert_common_sanitized('Wicked', 'Wicked - SPECIAL PREVIEW')
    assert_common_sanitized('Dune: Part Three', 'See It First – Dune: Part Three')
    assert_common_sanitized('The Wedding Entertainer', 'Centrepiece Gala: The Wedding Entertainer')
    assert_common_sanitized('Mediterranean Fever', 'Mediterranean Fever + ScreenTalk')
    assert_common_sanitized('Hamnet', 'Hamnet + Intro')
  end

  def test_common_rules_remove_bracketed_formats_and_editions
    assert_common_sanitized('Avatar', 'Avatar (3D)')
    assert_common_sanitized('The Devils', 'The Devils (4K Restoration)')
    assert_common_sanitized('Alien', 'Alien (4K)')
    assert_common_sanitized('Alien', 'Alien 4k')
    assert_common_sanitized('Jaws', 'Jaws (50th Anniversary 4K Restoration)')
    assert_common_sanitized('Jaws', 'Jaws (20th Anniversary Restoration)')
    assert_common_sanitized('Loveless', 'Loveless [10th Anniversary]')
    assert_common_sanitized('Tosca', 'Tosca (Encore)')
    assert_common_sanitized('Tosca', 'Tosca (2025 Encore)')
    assert_common_sanitized('Tosca', 'Tosca (Recorded)')
    assert_common_sanitized('Thunderbirds Double Bill', 'Thunderbirds 4k Restoration Double Bill')
    assert_common_sanitized('Spirited Away', 'Spirited Away (English Dubbed)')
  end

  def test_common_rules_remove_more_language_versions
    %w(Bengali Gujarati Japanese Romanian Vietnamese).each do |language|
      assert_common_sanitized('Chatni', "Chatni (#{language})")
    end
  end

  def test_common_rules_remove_trailing_anniversary
    assert_common_sanitized("Pan's Labyrinth", "Pan's Labyrinth 20th Anniversary 4K Restoration")
    assert_common_sanitized('Star Trek: First Contact', 'Star Trek: First Contact - 30th Anniversary')
    assert_common_sanitized("Little Theatre's 90th Anniversary: The Third Man", "Little Theatre's 90th Anniversary: The Third Man")
  end

  def test_common_rules_remove_more_q_and_a_spellings
    assert_common_sanitized('How Deep Is Your Love', 'How Deep Is Your Love + Eleanor Mortimer Dir. Q&A')
    assert_common_sanitized('I Swear', 'I Swear (with cast & crew Q&A)')
  end

  def test_common_rules_read_non_breaking_spaces_as_spaces
    assert_common_sanitized('Ghost Stories', "Norfolk Folklore Society presents: Ghost Stories")
    assert_common_sanitized('Gentle Monster', "Gentle Monster ")
  end

  def test_common_rules_remove_throwback_series
    assert_common_sanitized('Rocky', 'Throwback: Rocky (50th Anniversary)')
  end

  def test_common_rules_remove_full_stop_after_a_marker
    assert_common_sanitized('The Muppet Christmas Carol', 'The Muppet Christmas Carol (35mm).')
    assert_common_sanitized('Arthur Christmas', 'Arthur Christmas (15th Anniversary).')
    assert_common_sanitized('Thunderbirds Are Go...', 'Thunderbirds Are Go...')
  end

  def test_common_rules_name_paris_opera_as_an_event
    assert_common_sanitized('Paris Opera: La Bayadère', 'La Bayadère (Opéra de Paris)')
    assert_common_sanitized('Paris Opera: Giselle', 'Paris Opera Ballet: Giselle')
  end

  def test_common_rules_remove_festival_suffix
    assert_common_sanitized('Party USA', 'Party USA - NFF UK Premier')
  end

  def test_common_rules_remove_presenter_credit
    assert_common_sanitized('Zardoz', 'Bar Trash Presents: Zardoz')
    assert_common_sanitized('Terminator 2: Judgment Day', 'Cellar Door x ThoughtBubble presents: Terminator 2: Judgment Day')
    assert_common_sanitized('Mississippi Records presents A History', 'Mississippi Records presents A History')
  end

  def test_common_rules_remove_live_on_stage
    assert_common_sanitized('Starlight Express', 'Starlight Express – Live On Stage')
    assert_common_sanitized("Andrew Lloyd Webber's Starlight Express", "Andrew Lloyd Webber's Starlight Express - Live On Stage")
  end

  def test_common_rules_remove_more_festival_prefixes
    assert_common_sanitized('A Silent Voice', 'SLA 2026: A Silent Voice')
    assert_common_sanitized('Tell Me Everything', 'JFF 2026 : Tell Me Everything')
    assert_common_sanitized('A Useful Ghost', 'Queer East 26: A Useful Ghost')
  end

  def test_titles_in_capitals_are_title_cased
    assert_common_sanitized('The Lord of the Rings: The Return of the King', 'THE LORD OF THE RINGS: THE RETURN OF THE KING')
    assert_common_sanitized("Spider-Man: Don't Look Back", "SPIDER-MAN: DON'T LOOK BACK")
    assert_common_sanitized('Götterdämmerung', 'GÖTTERDÄMMERUNG')
    assert_common_sanitized('Rocky IV', 'ROCKY IV')
    assert_common_sanitized('Rocky V', 'ROCKY V')
    assert_common_sanitized('Derek vs Derek', 'DEREK VS DEREK')
    assert_common_sanitized('M3GAN 2.0', 'M3GAN 2.0')
    assert_common_sanitized('RRR', 'RRR')
    assert_common_sanitized("BTS 'Arirang' in Buenos Aires: Live Viewing", "BTS 'ARIRANG' IN BUENOS AIRES: LIVE VIEWING")
    assert_common_sanitized('Mr. Bean', 'MR. BEAN')
  end

  def test_titles_with_lowercase_keep_their_case
    assert_common_sanitized('JAK ZYC with friends', 'JAK ZYC with friends')
  end

  def test_common_rules_decapitalise_world_tour
    assert_common_sanitized("Enhypen World Tour 'Blood Saga'", "ENHYPEN WORLD TOUR 'BLOOD SAGA'")
    assert_common_sanitized("BTS World Tour 'Arirang' in Jakarta: Live Viewing", "BTS WORLD TOUR 'ARIRANG' IN JAKARTA: LIVE VIEWING")
  end

  def test_common_rules_remove_film_year
    assert_common_sanitized('Street Fighter', 'Street Fighter (2026)')
  end

  def test_common_rules_remove_film_year_before_other_markers
    assert_common_sanitized('Kung Fu Soccer', 'Kung Fu Soccer (2026) (Dubbed)')
  end

  def test_common_rules_remove_re_release
    assert_common_sanitized('Zindagi Na Milegi Dobara', 'Zindagi Na Milegi Dobara (Re-release) (Hindi)')
  end

  def test_common_rules_remove_lithuanian_version
    assert_common_sanitized('(ne)tobuli melagiai', '(ne)tobuli melagiai (Lithuanian)')
  end

  def test_common_rules_remove_season_prefix_and_year
    assert_common_sanitized('From Dusk Till Dawn', 'Horror Season 2026 From Dusk Till Dawn (1996)')
  end

  def test_film_year_from_trailing_year
    assert_equal(2026, Cinebase::TitleSanitizer.film_year('Street Fighter (2026)'))
    assert_equal(1996, Cinebase::TitleSanitizer.film_year('Horror Season 2026 From Dusk Till Dawn (1996)'))
  end

  def test_film_year_before_other_markers
    assert_equal(2026, Cinebase::TitleSanitizer.film_year('Kung Fu Soccer (2026) (Dubbed)'))
  end

  def test_film_year_without_trailing_year
    assert_nil(Cinebase::TitleSanitizer.film_year('Blade Runner 2049'))
    assert_nil(Cinebase::TitleSanitizer.film_year('2001: A Space Odyssey'))
    assert_nil(Cinebase::TitleSanitizer.film_year('(500) Days of Summer'))
    assert_nil(Cinebase::TitleSanitizer.film_year('Cine-Excess 2026: Scum Of The Earth'))
  end

  def test_common_rules_keep_titles_with_their_own_subtitles
    [
      'Harry Potter and the Deathly Hallows: Part 1',
      'Spider-Man: Brand New Day',
      'Hadestown: The Musical',
      'Rammstein - Live in Mexico City',
      'Ozzy & Black Sabbath: Back to the Beginning',
      "BTS 'Arirang' at Wembley: Live Viewing",
      '3 Days to Kill',
      'Blade Runner 2049',
      '2001: A Space Odyssey',
      '(500) Days of Summer',
      "We're Going on a Bear Hunt + Tiger Who Came To Tea",
      '4K Restoration Stories'
    ].each { |title| assert_common_sanitized(title, title) }
  end

  private

  def assert_common_sanitized(expected, title)
    assert_equal(expected, CommonSanitizer.new(title).sanitized)
  end
end
