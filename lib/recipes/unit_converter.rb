require 'measured'

module Recipes
  class UnitConverter
    CONVERSIONS = {
      units: {
        tspn: 1,
        tbsp: 3,
        cup: 48,
        quart: 192,
        pint: 96,
        gallon: 768
      },
      weight: {
        kilogram: 1,
        gram: 1000,
        pound: 2.20462,
        ounce: 35.274
      },
      temperature: {}
    }.freeze

    TEST_CONVERSIONS = {
      'sugar' => { 200 => 'cups' },
      'flour' => { 300 => 'tspn' },
      'vanilla' => { 85 => 'tbsp' },
      'water' => { 200 => 'quarts' }
    }.freeze

    def converter(value, from_unit, to_unit, category)
      from_base = value / CONVERSIONS[category][from_unit]
      from_base * CONVERSIONS[category][to_unit]
    end
  end
end
