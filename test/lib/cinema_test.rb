require_relative '../minitest_helper'

class TestCinema < Cinebase::Cinema
  def self.all; []; end
  def brand; 'TestBrand'; end
  def country_name; 'TestCountryName'; end
  def extended_address; 'TestExtendedAddress'; end
  def locality; 'TestLocality'; end
  def name; 'TestName'; end
  def postal_code; 'TestPostalCode'; end
  def street_address; 'TestStreetAddress'; end
  def url; 'TestUrl'; end
end

describe Cinebase::Cinema do
  describe 'as an abstract template class' do
    let(:described_class) { Cinebase::Cinema }

    describe 'required methods' do
      describe '.all' do
        subject { described_class.all }

        it 'raises an error' do
          -> { subject }.must_raise NotImplementedError
        end
      end

      describe '#id' do
        subject { described_class.new(123).id }

        it 'returns the passed id' do
          subject.must_equal(123)
        end
      end

      %i(adr address brand country_name extended_address locality name
         postal_code street_address url).each do |method|

        describe "##{method}" do
          subject { described_class.new(123).send(method) }

          it 'raises an error' do
            -> { subject }.must_raise NotImplementedError
          end
        end

      end
    end
  end

  describe 'with implemented subclass' do
    let(:described_class) { TestCinema }
    let(:id) { 123 }

    describe '.all' do
      subject { described_class.all }

      it 'returns a hash' do
        subject.must_be_instance_of(Array)
      end
    end

    describe '#adr' do
      subject { described_class.new(id).adr }

      it 'returns a hash' do
        subject.must_be_instance_of(Hash)
      end
    end

    describe '#address' do
      subject { described_class.new(id).address }

      it 'returns a hash' do
        subject.must_be_instance_of(Hash)
      end
    end

    describe '#brand' do
      subject { described_class.new(id).brand }

      it 'returns the subclass brand' do
        subject.must_equal('TestBrand')
      end
    end

    describe '#country_name' do
      subject { described_class.new(id).country_name }

      it 'returns the subclass country' do
        subject.must_equal('TestCountryName')
      end
    end

    describe '#extended_address' do
      subject { described_class.new(id).extended_address }

      it 'returns the subclass extended address' do
        subject.must_equal('TestExtendedAddress')
      end
    end

    describe '#locality' do
      subject { described_class.new(id).locality }

      it 'returns the subclass locality' do
        subject.must_equal('TestLocality')
      end
    end

    describe '#name' do
      subject { described_class.new(id).name }

      it 'returns the subclass name' do
        subject.must_equal('TestName')
      end
    end

    describe '#postal_code' do
      subject { described_class.new(id).postal_code }

      it 'returns the subclass postal code' do
        subject.must_equal('TestPostalCode')
      end
    end

    describe '#street_address' do
      subject { described_class.new(id).street_address }

      it 'returns the subclass address' do
        subject.must_equal('TestStreetAddress')
      end
    end

    describe '#url' do
      subject { described_class.new(id).url }

      it 'returns the subclass address' do
        subject.must_equal('TestUrl')
      end
    end
  end
end
