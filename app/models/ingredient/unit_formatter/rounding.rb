class Ingredient
  class UnitFormatter
    # Snaps impractical tbsp/tsp amounts to a friendlier cup or teaspoon
    # measurement, falling back to a two-unit split (e.g. "1 3/4 c" plus
    # "2 tbsp") when a single unit can't represent the amount closely enough.
    module Rounding
      # Fractional cup amounts worth snapping to: quarters, thirds, halves,
      # and a whole cup (a "1" carries into the next whole number of cups).
      CUP_FRACTIONS = [0r, 1r / 4, 1r / 3, 1r / 2, 2r / 3, 3r / 4, 1r].freeze

      # Standard measuring-spoon sizes: quarter and half teaspoons.
      TSP_FRACTIONS = [0r, 1r / 4, 1r / 2, 3r / 4, 1r].freeze

      # A rounded amount is only used if it's within 5% of the original
      # quantity, so rounding never meaningfully changes the recipe.
      ROUNDING_TOLERANCE = 1r / 20

      private

      # Convert tbsp/tsp to a cup amount if it's at or near a common cup
      # fraction (quarters, thirds, halves) without materially changing the
      # recipe's quantity.
      def rounded_cup_fit(unit_key)
        return unless volume_unit? && %w[tsp tbsp].include?(unit_key)

        nearest_nice_amount(base_amount / units_per_base('c'), CUP_FRACTIONS) { |quantity| ['c', quantity] }
      end

      # Round a leftover teaspoon amount to the nearest quarter or half
      # teaspoon, the smallest measuring spoons commonly available.
      def rounded_tsp_fit(unit_key)
        return unless unit_key == 'tsp'

        nearest_nice_amount(base_amount / units_per_base('tsp'), TSP_FRACTIONS) { |quantity| ['tsp', quantity] }
      end

      # Snaps quantity to the nearest whole-number-plus-fraction amount from
      # allowed_fractions, yielding it only if that stays within
      # ROUNDING_TOLERANCE of the original quantity.
      def nearest_nice_amount(quantity, allowed_fractions)
        whole = quantity.floor
        fraction = allowed_fractions.min_by { |candidate| (quantity - whole - candidate).abs }
        whole += 1 if fraction == 1
        rounded = fraction == 1 ? whole : whole + fraction
        return if rounded.zero? || !within_rounding_tolerance?(quantity, rounded)

        yield rounded
      end

      def within_rounding_tolerance?(original, rounded)
        return true if original == rounded

        ((original - rounded).abs / original) <= ROUNDING_TOLERANCE
      end

      # Splits an amount that doesn't cleanly round into a single cup fraction
      # into a cup amount plus an exact tbsp/tsp remainder, e.g. "14 tbsp"
      # becomes 3/4 c (primary) plus 2 tbsp (remainder).
      def compound_fit(unit_key)
        return unless volume_unit? && %w[tsp tbsp].include?(unit_key)

        primary_quantity = primary_cup_quantity
        return unless primary_quantity

        remainder_base = base_amount - (primary_quantity * units_per_base('c'))
        return if remainder_base.zero?

        remainder_unit_key, remainder_quantity = remainder_fit(remainder_base)
        ['c', primary_quantity, remainder_unit_key, remainder_quantity]
      end

      # The largest whole-cups-plus-nice-fraction amount at or below the
      # total, or nil if the total doesn't even reach a quarter cup.
      def primary_cup_quantity
        cup_quantity = base_amount / units_per_base('c')
        whole_cups = cup_quantity.floor
        primary = whole_cups + largest_cup_fraction_at_or_below(cup_quantity - whole_cups)
        return if primary.zero?

        primary
      end

      def largest_cup_fraction_at_or_below(remainder)
        CUP_FRACTIONS.select { |fraction| fraction <= remainder }.max
      end

      # Expresses a remainder in whole tablespoons when possible, falling
      # back to teaspoons (the finest volume unit) so it's always exact.
      def remainder_fit(remainder_base)
        tbsp_quantity = remainder_base / units_per_base('tbsp')
        return ['tbsp', tbsp_quantity] if tbsp_quantity.denominator == 1

        ['tsp', remainder_base]
      end

      # Splits an amount of at least a gallon that isn't an exact whole
      # number of gallons into whole gallons plus a cup remainder, e.g.
      # "89 c" becomes 5 gal (primary) plus 9 c (remainder), so scaling up
      # doesn't jump straight from a large cup count to a lone gallon figure.
      def gallon_compound_fit(unit_key)
        return unless volume_unit? && %w[c tbsp tsp].include?(unit_key)

        whole_gallons = base_amount / units_per_base('gal')
        return if whole_gallons < 1

        remainder_base = base_amount - (whole_gallons.floor * units_per_base('gal'))
        return if remainder_base.zero?

        remainder_unit_key, remainder_quantity = rounded_cup_remainder(remainder_base)
        ['gal', whole_gallons.floor, remainder_unit_key, remainder_quantity]
      end

      # A cup remainder snaps to a nice fraction (quarters, thirds, halves)
      # when close enough, otherwise it's shown as its exact value.
      def rounded_cup_remainder(remainder_base)
        cup_quantity = remainder_base / units_per_base('c')
        nice_quantity = nearest_nice_amount(cup_quantity, CUP_FRACTIONS) { |quantity| quantity }

        ['c', nice_quantity || cup_quantity]
      end
    end
  end
end
