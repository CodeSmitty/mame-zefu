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
        update_ingredient_with_conversion(ingredient, base_unit)
      rescue Measured::UnitError
        uncovertable_ingredient(ingredient)
      end
    end

    private

    def find_best_unit(converter, sorted_units)
      current_index = sorted_units.index(converter.unit.name.to_s)
      base_unit = converter
      ((current_index + 1)...sorted_units.length).each do |i|
        candidate = sorted_units[i]
        converted = base_unit.convert_to(candidate)
        break unless converted.value >= 1

        base_unit = converted
      end
      base_unit
    end

    def update_ingredient_with_conversion(ingredient, base_unit)
      formatted_value = Fractional.new(base_unit.value.to_f, to_human: true).to_s
      ingredient[:converted_quantity] = formatted_value
      ingredient[:converted_unit] = base_unit.unit.name.to_s
      ingredient[:converted_description] = "#{formatted_value} #{base_unit.unit.name} #{ingredient[:ingredient]}"
    end

    def uncovertable_ingredient(ingredient)
      ingredient[:converted_quantity] = nil
      ingredient[:converted_unit] = nil
      ingredient[:converted_description] = nil
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
