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
        street_address:   street_address,
        extended_address: extended_address,
        locality:         locality,
        postal_code:      postal_code,
        country_name:     country_name
      }.reject { |_, v| v.nil? }
    end
    alias_method :address, :adr

    [:brand, :country_name, :extended_address, :locality, :name, :postal_code,
     :street_address, :url].each do |method|
      define_method(method) do
        fail NotImplementedError, "This #{self.class} cannot respond to: "
      end
    end

    def full_name
      @full_name ||= "#{brand} #{name}"
    end

    def slug
      @slug ||= full_name.downcase.gsub(/[^0-9a-z ]/, '').gsub(/\s+/, '-')
    end
  end
end
