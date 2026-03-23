require_relative 'ingredient_constants'

module Recipes
  class UnitConverter
    include IngredientConstants

    def converter(scaled_ingredients)
      scaled_ingredients.each do |ingredient|
        unit_str = ingredient[:unit].to_s.strip.downcase
        unit_converter = sort_volume_or_weight_units(ingredient[:scaled_quantity], unit_str)
        converter = unit_converter[:converter].new(ingredient[:scaled_quantity], unit_str)
        sorted_units = unit_converter[:sorted_units]
        base_unit = find_best_unit(converter, sorted_units)
        update_conversion(ingredient, base_unit)
      rescue Measured::UnitError
        uncovertable_ingredient(ingredient)
      end
    end

    private

    def find_best_unit(converter, sorted_units)
      current_index = unit_index(converter, sorted_units)
      return converter if current_index.nil?

      scaled_up_unit, scaled_up_index = scale_up(converter, current_index, sorted_units)
      scale_down(scaled_up_unit, scaled_up_index, sorted_units)
    end

    def unit_index(converter, sorted_units)
      unit_name = converter.unit.name.to_s
      sorted_units.map(&:to_s).index(unit_name)
    end

    def scale_up(base_unit, index, sorted_units)
      while index < (sorted_units.length - 1)
        candidate = sorted_units[index + 1]
        converted = base_unit.convert_to(candidate)
        break unless converted.value >= 1

        base_unit = converted
        index += 1
      end
      [base_unit, index]
    end

    def scale_down(base_unit, index, sorted_units)
      while index.positive? && base_unit.value < 1
        candidate = sorted_units[index - 1]
        base_unit = base_unit.convert_to(candidate)
        index -= 1
      end
      base_unit
    end

    def update_conversion(ingredient, base_unit) # rubocop:disable Metrics/AbcSize
      formatted_value = Fractional.new(base_unit.value.to_f, to_human: true).to_s
      ingredient[:converted_quantity] = formatted_value

      if base_unit.unit
        unit_name = base_unit.unit.name.to_s
        ingredient[:converted_unit] = unit_name
        ingredient[:converted_description] = "#{formatted_value} #{base_unit.unit.name} #{ingredient[:ingredient]}"
      else
        ingredient[:converted_unit] = nil
        ingredient[:converted_description] = "#{formatted_value} #{ingredient[:ingredient]}"
      end
    end

    def uncovertable_ingredient(ingredient)
      ingredient[:converted_quantity] = Fractional.new(ingredient[:scaled_quantity].to_f, to_human: true).to_s
      ingredient[:converted_unit] = nil
      ingredient[:converted_description] =
        "#{ingredient[:converted_quantity]}#{ingredient[:converted_unit]} #{ingredient[:ingredient]}"
    end

    def sort_volume_or_weight_units(_scaled_quantity, unit_str) # rubocop:disable Metrics/MethodLength
      if Recipes::IngredientConstants::VOLUME_UNITS.key?(unit_str)
        {
          converter: Recipes::Volume,
          unit_system: Recipes::Volume.unit_system,
          sorted_units: VOLUME_ORDER
        }
      elsif Recipes::IngredientConstants::WEIGHT_UNITS.key?(unit_str)
        {
          converter: Recipes::Weight,
          unit_system: Recipes::Weight.unit_system,
          sorted_units: WEIGHT_ORDER
        }
      else
        raise Measured::UnitError, "Unit '#{unit_str}' is not recognized as volume or weight."
      end
    end
  end
end
