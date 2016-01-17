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

describe Cinebase::TitleSanitizer do
  describe 'as an abstract template class' do
    let(:described_class) { Cinebase::TitleSanitizer }

    describe '#sanitized' do
      subject { described_class.new(title).sanitized }

      let(:title) { 'anything' }

      it 'raises NotImplementedError' do
        -> { subject }.must_raise NotImplementedError
      end
    end
  end

  describe 'with implemented subclass' do
    let(:described_class) { TestSanitizer }

    describe '#sanitized' do
      subject { described_class.new(title).sanitized }

      describe 'remove elements in remove method' do
        let(:title) { 'title remove one' }

        it 'removes elements from sanitized title' do
          subject.must_equal 'title one'
        end
      end

      describe 'replace elements in remove method' do
        let(:title) { 'Bolshoi - one dance' }

        it 'removes elements from sanitized title' do
          subject.must_equal 'Bolshoi: one dance'
        end
      end
    end
  end
end
