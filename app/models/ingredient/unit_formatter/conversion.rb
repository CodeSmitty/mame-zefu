class Ingredient
  class UnitFormatter
    # Public, alias-aware unit-conversion helpers reused by both
    # UnitFormatter itself and external callers (e.g. debug tooling) that
    # need the same math without duplicating it. Mixed in as both instance
    # and class methods (see UnitFormatter's `include` and `extend`).
    module Conversion
      include Constants

      # Alias-aware lookup of a unit's size relative to its family's
      # smallest unit (tsp or g), or nil for an unrecognized unit.
      def units_per_base(unit)
        key = canonical_unit(unit)
        VOLUME_UNITS[key] || WEIGHT_UNITS[key]
      end

      def canonical_unit(unit)
        key = unit.to_s.strip.downcase
        VOLUME_ALIASES[key] || WEIGHT_ALIASES[key] || key
      end

      def rational_string(value)
        return unless value

        "#{value.numerator}/#{value.denominator}"
      end

      # The combined amount of a (possibly compound) quantity/unit pair,
      # expressed in its family's smallest unit, or nil if the unit isn't
      # recognized.
      def total_base_amount(quantity:, unit:, quantity_secondary: nil, unit_secondary: nil)
        per_base = units_per_base(unit)
        return unless per_base

        total = quantity.to_r * per_base
        return total unless quantity_secondary

        secondary_per_base = units_per_base(unit_secondary)
        return unless secondary_per_base

        total + (quantity_secondary.to_r * secondary_per_base)
      end

      # The equivalent quantity for a base amount expressed in a given
      # unit, or nil if the unit isn't recognized.
      def quantity_in(unit:, base_amount:)
        return unless base_amount

        per_base = units_per_base(unit)
        return unless per_base

        base_amount / per_base
      end
    end
  end
end
