require_relative '../minitest_helper'
require 'date'

class TestScreening < Cinebase::Screening
  def self.at(cinema_id); cinema_id; end
end

describe Cinebase::Screening do
  describe 'as an abstract template class' do
    let(:described_class) { Cinebase::Screening }

    describe 'required methods' do
      describe '.at(id)' do
        subject { described_class.at(123) }

        it 'raises an error' do
          -> { subject }.must_raise NotImplementedError
        end
      end
    end

    describe 'without required hash options' do
      subject { {} }

      %i(booking_url cinema_id cinema_name dimension film_name showing_on
         showing_at).each do |method|
        describe "##{method}" do
          subject { described_class.new(options).send(method) }

          it 'raises an error' do
            -> { subject }.must_raise NameError
          end
        end
      end
    end

    describe 'with required hash options' do
      let(:options) do
        {
          cinema_id:   123,
          cinema_name: 'Cinema',
          film_name:   'Film Name',
          time:        DateTime.now
        }
      end

      describe '#booking_url' do
        subject { described_class.new(options).booking_url }

        it 'returns nil' do
          subject.must_equal(nil)
        end
      end

      describe '#cinema_id' do
        subject { described_class.new(options).cinema_id }
        it 'returns the value' do
          subject.must_equal(123)
        end
      end

      describe '#cinema_name' do
        subject { described_class.new(options).cinema_name }
        it 'returns the value' do
          subject.must_equal('Cinema')
        end
      end

      describe '#dimension' do
        subject { described_class.new(options).dimension }

        it 'returns 2d default' do
          subject.must_equal('2d')
        end

        describe 'with array passed in' do
          let(:options) do
            {
              cinema_id:   123,
              dimension:   '3d',
              cinema_name: 'Cinema',
              film_name:   'Film Name',
              time:        DateTime.now
            }
          end

          it 'returns a sorted array' do
            subject.must_equal('3d')
          end
        end
      end

      describe '#film_name' do
        subject { described_class.new(options).film_name }
        it 'returns the value' do
          subject.must_equal('Film Name')
        end
      end

      describe '#showing_on' do
        subject { described_class.new(options).showing_on }
        it 'returns the value' do
          subject.must_equal(options[:time].to_date)
        end
      end

      describe '#showing_at' do
        subject { described_class.new(options).showing_at }
        it 'returns the value' do
          subject.must_equal(options[:time])
        end
      end

      describe '#variant' do
        subject { described_class.new(options).variant }

        it 'returns an array' do
          subject.must_equal([])
        end

        describe 'with array passed in' do
          let(:options) do
            {
              cinema_id:   123,
              cinema_name: 'Cinema',
              film_name:   'Film Name',
              time:        DateTime.now,
              variant:     %w(so here we are)
            }
          end

          it 'returns a sorted array' do
            subject.must_equal(%w(are here so we))
          end
        end

        describe 'with string passed in' do
          let(:options) do
            {
              cinema_id:   123,
              cinema_name: 'Cinema',
              film_name:   'Film Name',
              time:        DateTime.now,
              variant:     'so here we are'
            }
          end

          it 'returns a sorted array' do
            subject.must_equal(%w(are here so we))
          end
        end
      end
    end
  end

  describe 'with implemented subclass' do
    let(:described_class) { TestScreening }

    describe '.at(cinema_id)' do
      subject { described_class.at(123) }
      it 'returns' do
        subject.must_equal(123)
      end
    end
  end
end
