module Cinebase
  # Sabitize titles base class
  TitleSanitizer = Struct.new(:title) do
    def sanitized
      @sanitized ||= begin
        sanitized = title
        remove.each do |pattern|
          sanitized.gsub! pattern, ''
        end
        replace.each do |pattern, prefix|
          sanitized.gsub!(pattern) { |_| prefix + $1 }
        end
        sanitized.squeeze(' ').strip
      end
    end

    private

    def remove
      fail NotImplementedError, "This #{self.class} cannot respond to: "
    end

    def replace
      fail NotImplementedError, "This #{self.class} cannot respond to: "
    end
  end
end
