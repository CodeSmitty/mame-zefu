class Ingredient
  class FractionNormalizer
    include Constants

    FRACTION_PATTERN = Regexp.union(FRACTION_MAP.keys)

    def self.normalize(text)
      new.normalize(text)
    end

    def normalize(text)
      # Matches whole number immediately followed by a unicode fraction, e.g. "1¼".
      normalized_text = text.gsub(/(\d)(#{FRACTION_PATTERN})/) do
        "#{::Regexp.last_match(1)} #{FRACTION_MAP[::Regexp.last_match(2)]}"
      end

      # Matches standalone unicode fractions, e.g. "½".
      normalized_text = normalized_text.gsub(FRACTION_PATTERN) { |match| FRACTION_MAP[match] }

      # Matches mixed numbers written as "2 1/2" or "2-1/2".
      # We only want to convert standalone mixed-number forms, not fraction ranges
      # such as "1/4-1/2" where the second fraction should remain intact.
      normalized_text.gsub(%r{(?:\A|(?<=\s))(\d+)[\s-]+(\d+)/(\d+)}) do
        whole = ::Regexp.last_match(1).to_i
        num   = ::Regexp.last_match(2).to_i
        den   = ::Regexp.last_match(3).to_i
        "#{(whole * den) + num}/#{den}"
      end
    end
  end
end
