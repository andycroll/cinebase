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

      describe '#adr' do
        subject { described_class.new(123).adr }

        it 'returns the passed id' do
          subject.must_be_instance_of(Hash)
        end

        it 'contains all the requisite keys' do
          subject.keys.must_equal([:street_address, :extended_address,
                                   :locality, :region, :postal_code,
                                   :country_name])
        end
      end

      %i(street_address extended_address locality region postal_code
         country_name).each do |method|

        describe "##{method}" do
          subject { described_class.new(123).send(method) }

          it 'returns the empty string' do
            subject.must_equal('')
          end
        end
      end

      describe '#id' do
        subject { described_class.new(123).id }

        it 'returns the passed id' do
          subject.must_equal(123)
        end
      end

      %i(brand full_name name slug url).each do |method|

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

      it 'contains all the requisite keys' do
        subject.keys.must_equal([:street_address, :extended_address,
                                 :locality, :region, :postal_code,
                                 :country_name])
      end
    end

    describe '#address' do
      subject { described_class.new(id).address }

      it 'returns a hash' do
        subject.must_be_instance_of(Hash)
      end

      it 'contains all the requisite keys' do
        subject.keys.must_equal([:street_address, :extended_address,
                                 :locality, :region, :postal_code,
                                 :country_name])
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

    describe '#full_name' do
      subject { described_class.new(id).full_name }

      it 'returns the subclass name' do
        subject.must_equal('TestBrand TestName')
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

    describe '#region' do
      subject { described_class.new(id).region }

      it 'returns the subclass region' do
        subject.must_equal('TestRegion')
      end
    end

    describe '#slug' do
      subject { described_class.new(id).slug }

      it 'returns the subclass name' do
        subject.must_equal('testbrand-testname')
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
