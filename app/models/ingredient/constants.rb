class Ingredient
  module Constants
    FRACTION_MAP = {
      '½' => '1/2',
      '⅓' => '1/3', '⅔' => '2/3',
      '¼' => '1/4', '¾' => '3/4',
      '⅕' => '1/5', '⅖' => '2/5', '⅗' => '3/5', '⅘' => '4/5',
      '⅙' => '1/6', '⅚' => '5/6',
      '⅐' => '1/7',
      '⅛' => '1/8', '⅜' => '3/8', '⅝' => '5/8', '⅞' => '7/8',
      '⅑' => '1/9',
      '⅒' => '1/10'
    }.freeze

    # Canonical unit key => size relative to the smallest unit in its family (tsp/g).
    VOLUME_UNITS = {
      'tsp' => 1r,
      'tbsp' => 3r,
      'c' => 48r,
      'pt' => 96r,
      'qt' => 192r,
      'gal' => 768r
    }.freeze

    WEIGHT_UNITS = {
      'g' => 1r,
      'kg' => 1000r,
      'oz' => 28.3495r,
      'lb' => 16 * 28.3495r
    }.freeze

    VOLUME_ALIASES = {
      'teaspoon' => 'tsp', 'teaspoons' => 'tsp', 'tspn' => 'tsp',
      'tablespoon' => 'tbsp', 'tablespoons' => 'tbsp', 'tbspn' => 'tbsp',
      'cup' => 'c', 'cups' => 'c',
      'pint' => 'pt', 'pints' => 'pt',
      'quart' => 'qt', 'quarts' => 'qt',
      'gallon' => 'gal', 'gallons' => 'gal'
    }.freeze

    WEIGHT_ALIASES = {
      'gram' => 'g', 'grams' => 'g',
      'kilogram' => 'kg', 'kilograms' => 'kg',
      'ounce' => 'oz', 'ounces' => 'oz',
      'pound' => 'lb', 'pounds' => 'lb', 'lbs' => 'lb'
    }.freeze

    VOLUME_ORDER = %w[tsp tbsp c pt qt gal].freeze
    WEIGHT_ORDER = %w[g oz lb kg].freeze

    METRIC_WEIGHT_ORDER = %w[g kg].freeze
    IMPERIAL_WEIGHT_ORDER = %w[oz lb].freeze

    WEIGHT_LADDER_FOR_UNIT = {
      'g' => METRIC_WEIGHT_ORDER,
      'kg' => METRIC_WEIGHT_ORDER,
      'oz' => IMPERIAL_WEIGHT_ORDER,
      'lb' => IMPERIAL_WEIGHT_ORDER
    }.freeze
  end
end
