module Cinebase
  # Cinema base class
  class Cinema
    attr_reader :id

    def initialize(id)
      @id = id
    end

    def self.all
      fail NotImplementedError, "This #{self.class} cannot respond to: "
    end

    def adr
      {
        street_address:   nil,
        extended_address: nil,
        locality:         nil,
        region:           nil,
        postal_code:      nil,
        country_name:     nil
      }
    end
    alias_method :address, :adr

    def country_name
      adr[:country_name].to_s
    end

    def extended_address
      adr[:extended_address].to_s
    end

    def full_name
      @full_name ||= "#{brand} #{name}"
    end

    def locality
      adr[:locality].to_s
    end

    def postal_code
      adr[:postal_code].to_s
    end

    def region
      adr[:region].to_s
    end

    def slug
      @slug ||= full_name.downcase.gsub(/[^0-9a-z ]/, '').gsub(/\s+/, '-')
    end

    def street_address
      adr[:street_address].to_s
    end

    %i(brand name url).each do |method|
      define_method(method) do
        fail NotImplementedError, "This #{self.class} cannot respond to: "
      end
    end
  end
end
