module Recipes
  module IngredientConstants
    FRACTION_MAP = {
      '½' => '1/2', '⅓' => '1/3', '⅔' => '2/3',
      '¼' => '1/4', '¾' => '3/4',
      '⅕' => '1/5', '⅖' => '2/5', '⅗' => '3/5', '⅘' => '4/5',
      '⅙' => '1/6', '⅚' => '5/6',
      '⅐' => '1/7',
      '⅛' => '1/8', '⅜' => '3/8', '⅝' => '5/8', '⅞' => '7/8',
      '⅑' => '1/9',
      '⅒' => '1/10'
    }.freeze

    DO_NOT_SCALE = %w[
      salt
      kosher salt
      sea salt
      salt and pepper
      black pepper
      pepper
      water
      oil
    ].freeze

    VOLUME_UNITS = {
      'tsp' => 1,
      'tspn' => 1,
      'teaspoon' => 1,
      'teaspoons' => 1,
      'tbsp' => 3,
      'tablespoon' => 3,
      'tablespoons' => 3,
      'cup' => 48,
      'cups' => 48,
      'pint' => 96,
      'pints' => 96,
      'quart' => 192,
      'quarts' => 192,
      'gallon' => 768,
      'gallons' => 768
    }.freeze

    VOLUME_ORDER = %w[tsp tbsp cup pint quart gallon].freeze

    WEIGHT_UNITS = {
      'gram' => 1,
      'grams' => 1,
      'kilogram' => 1000,
      'kilograms' => 1000,
      'pound' => 453.59237,
      'pounds' => 453.59237,
      'ounce' => 28.3495,
      'ounces' => 28.3495
    }.freeze

    WEIGHT_ORDER = %w[gram kilogram ounce pound].freeze
  end
end
