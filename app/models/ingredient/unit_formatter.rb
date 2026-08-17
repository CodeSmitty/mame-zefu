class Ingredient
  # Converts a scaled quantity/unit into the best-fitting display unit within
  # the same measurement family (volume or weight), e.g. "3 tsp" becomes
  # "1 tbsp", "8 tbsp" becomes "1/2 c", "16 tsp" becomes "1/3 c", and
  # "16 oz" becomes "1 lb".
  class UnitFormatter
    include Constants

    # Cup amounts smaller than a whole cup are only worth showing as a
    # fraction of a cup when they land exactly on a common measure: a
    # quarter (1/4, 1/2, 3/4) or a third (1/3, 2/3).
    DISPLAYABLE_CUP_FRACTION_DENOMINATORS = [2, 3, 4].freeze

    Result = Struct.new(:quantity, :unit)

    def initialize(quantity:, unit:)
      @quantity = quantity.to_r
      @unit = unit.to_s.strip
      @unit_key = canonical_unit(@unit)
    end

    def call
      return Result.new(@quantity.to_s, @unit) unless convertible?

      best_unit_key, best_quantity = best_fit
      Result.new(best_quantity.to_s, best_unit_key)
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

    def canonical_unit(unit)
      key = unit.downcase
      VOLUME_ALIASES[key] || WEIGHT_ALIASES[key] || key
    end

    # The quantity expressed in the smallest unit of its family (tsp or g).
    def base_amount
      @quantity * units_per_base(@unit_key)
    end

    def units_per_base(unit_key)
      VOLUME_UNITS[unit_key] || WEIGHT_UNITS[unit_key]
    end

    # The units to consider, ordered from smallest to largest.
    def unit_ladder
      return VOLUME_ORDER if volume_unit?

      WEIGHT_LADDER_FOR_UNIT[@unit_key] || WEIGHT_ORDER
    end

    # Finds the largest unit in the ladder whose whole-number quantity is
    # at least 1, falling back to a cup fraction for tbsp amounts.
    def best_fit
      units = unit_ladder
      index = promote_to_largest_whole_unit(units, units.index(@unit_key) || 0)
      index = demote_to_smallest_whole_unit(units, index)
      unit_key = units[index]

      return cup_fraction_fit if unit_key == 'tbsp'

      [unit_key, base_amount / units_per_base(unit_key)]
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
      (base_amount / units_per_base(unit_key)) >= 1
    end

    # Convert tbsp to a fraction of a cup if it lands on a common measure.
    def cup_fraction_fit
      cup_quantity = base_amount / units_per_base('c')
      return ['tbsp', base_amount / units_per_base('tbsp')] unless displayable_cup_fraction?(cup_quantity)

      ['c', cup_quantity]
    end

    def displayable_cup_fraction?(cup_quantity)
      DISPLAYABLE_CUP_FRACTION_DENOMINATORS.include?(cup_quantity.denominator)
    end
  end
end
