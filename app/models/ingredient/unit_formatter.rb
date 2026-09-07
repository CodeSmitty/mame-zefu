class Ingredient
  # Converts a scaled quantity/unit into the best-fitting display unit within
  # the same measurement family (volume or weight), e.g. "3 tsp" becomes
  # "1 tbsp", "8 tbsp" becomes "1/2 c", "16 tsp" becomes "1/3 c", and
  # "16 oz" becomes "1 lb".
  class UnitFormatter
    include Constants
    include Rounding
    include Conversion
    extend Conversion

    Result = Struct.new(:quantity, :unit, :quantity_max, :quantity_secondary, :unit_secondary)

    def initialize(quantity:, unit:, quantity_max: nil, scale: 1)
      @quantity = quantity.to_r * scale.to_r
      @quantity_max = quantity_max&.to_r&.*(scale.to_r)
      @unit = unit.to_s.strip
      @unit_key = canonical_unit(@unit)
    end

    def call
      return Result.new(rational_string(@quantity), @unit, rational_string(@quantity_max)) unless convertible?

      unit_key, quantity, secondary_unit_key, secondary_quantity = best_fit
      Result.new(
        rational_string(quantity),
        unit_key,
        rational_string(quantity_max_in(unit_key)),
        rational_string(secondary_quantity),
        secondary_unit_key
      )
    end

    private

    def convertible?
      volume_unit? || weight_unit?
    end

    def volume_unit?
      VOLUME_UNITS.key?(@unit_key)
    end

    def weight_unit?
      WEIGHT_UNITS.key?(@unit_key)
    end

    # The quantity expressed in the smallest unit of its family (tsp or g).
    def base_amount
      @quantity * units_per_base(@unit_key)
    end

    def quantity_max_in(unit_key)
      return unless @quantity_max

      @quantity_max * units_per_base(@unit_key) / units_per_base(unit_key)
    end

    # The units to consider, ordered from smallest to largest.
    def unit_ladder
      return VOLUME_ORDER if volume_unit?

      WEIGHT_LADDER_FOR_UNIT[@unit_key] || WEIGHT_ORDER
    end

    # Finds the largest unit in the ladder whose whole-number quantity is
    # at least 1, falling back to a cup or teaspoon fraction, and finally to
    # a two-unit split (e.g. "30 tbsp" becomes "1 3/4 c" plus "2 tbsp") so
    # that impractical amounts round to a friendlier measurement.
    def best_fit
      units = unit_ladder
      index = promote_to_largest_whole_unit(units, units.index(@unit_key) || 0)
      index = demote_to_smallest_whole_unit(units, index)
      fitted_measurement(units[index])
    end

    def fitted_measurement(unit_key)
      gallon_compound = gallon_compound_fit(unit_key)
      return gallon_compound if gallon_compound

      cup_fit = rounded_cup_fit(unit_key)
      return [*cup_fit, nil, nil] if cup_fit

      compound = compound_fit(unit_key)
      return compound if compound

      tsp_fit = rounded_tsp_fit(unit_key)
      return [*tsp_fit, nil, nil] if tsp_fit

      [unit_key, base_amount / units_per_base(unit_key), nil, nil]
    end

    def promote_to_largest_whole_unit(units, index)
      index += 1 while index < units.length - 1 && whole_quantity_in?(units[index + 1])
      index
    end

    def demote_to_smallest_whole_unit(units, index)
      index -= 1 while index.positive? && !whole_quantity_in?(units[index])
      index
    end

    def whole_quantity_in?(unit_key)
      (base_amount % units_per_base(unit_key)).zero?
    end
  end
end
