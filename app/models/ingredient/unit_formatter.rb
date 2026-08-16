require_relative 'constants'

class Ingredient
  # Converts a scaled quantity/unit into the best-fitting display unit,
  # e.g. "8 tbsp" becomes "1/2 cup".
  class UnitFormatter
    include Constants

    Result = Struct.new(:quantity, :unit)

    def initialize(quantity:, unit:)
      @quantity = quantity.to_r
      @unit = unit.to_s.strip
      @unit_key = canonical_unit(@unit)
    end

    def call
      return Result.new(@quantity.to_s, @unit) unless convertible?

      best_key, best_quantity = best_fit
      Result.new(best_quantity.to_s, best_key)
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

    def base_amount
      @quantity * scale_for(@unit_key)
    end

    def scale_for(unit_key)
      VOLUME_UNITS[unit_key] || WEIGHT_UNITS[unit_key]
    end

    def order
      return VOLUME_ORDER if volume_unit?

      WEIGHT_LADDER_FOR_UNIT[@unit_key] || WEIGHT_ORDER
    end

    def best_fit
      units = order
      index = units.index(@unit_key) || 0
      index = scale_up(units, index)

      [units[index], base_amount / scale_for(units[index])]
    end

    def scale_up(units, index)
      index += 1 while index < units.length - 1 && (base_amount / scale_for(units[index + 1])) >= 1
      scale_down(units, index)
    end

    def scale_down(units, index)
      index -= 1 while index.positive? && (base_amount / scale_for(units[index])) < 1
      index
    end
  end
end
