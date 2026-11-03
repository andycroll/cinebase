require_relative '../minitest_helper'

class AudienceTest < Minitest::Test
  def test_variants_from_title_labels
    {
      'Toddler Club: The Polar Express' => %w(kids),
      'Toddler Kino: Stick Man' => %w(kids),
      'Kids Club: Paddington' => %w(kids),
      'Relaxed Screening: Wicked' => %w(relaxed),
      'Relaxed: Wicked' => %w(relaxed),
      'Wicked - Sensory Friendly Screening' => %w(relaxed),
      'Wicked: Sensory Friendly Screening' => %w(relaxed),
      'Dog-Friendly Screening: Wicked' => %w(dog_friendly),
      "Dog-Friendly: Pan's Labyrinth" => %w(dog_friendly),
      'The Trip to the Northern Lights: Preview and Q&A' => %w(preview),
      'Wicked (Parent & Baby Only Show)' => %w(baby),
      'Wicked - Unlimited Screening' => %w(members),
      'Wicked Unlimited Screening' => %w(members),
      'Wicked - MyOmnipass Member Screening' => %w(members),
      'Wicked - Preview' => %w(preview),
      'Wicked - SPECIAL PREVIEW' => %w(preview),
      'See It First – Dune: Part Three' => %w(preview),
      'Irregular at Magic High School (Japanese Language with English Subtitles)' => %w(subtitled)
    }.each do |title, variants|
      assert_equal(variants, Cinebase::Audience.variants(title), title)
    end
  end

  def test_variants_without_label_are_empty
    assert_empty(Cinebase::Audience.variants('The Relaxed Club'))
    assert_empty(Cinebase::Audience.variants('Sneak Previews'))
  end
end
