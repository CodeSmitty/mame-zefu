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

    VOLUME_UNITS = {
      'tsp' => 1,
      'tspn' => 1,
      'teaspoon' => 1,
      'teaspoons' => 1,
      'tbsp' => 3,
      'tbspn' => 3,
      'tablespoon' => 3,
      'tablespoons' => 3,
      'cup' => 48,
      'cups' => 48,
      'qt' => 192,
      'quart' => 192,
      'quarts' => 192,
      'gal' => 768,
      'gallon' => 768,
      'gallons' => 768
    }.freeze

    VOLUME_ORDER = %w[tsp tbsp cup qt gal].freeze

    WEIGHT_UNITS = {
      'g' => 1,
      'gram' => 1,
      'grams' => 1,
      'kg' => 1000,
      'kilogram' => 1000,
      'kilograms' => 1000,
      'pound' => 453.59237,
      'pounds' => 453.59237,
      'lb' => 453.59237,
      'lbs' => 453.59237,
      'ounce' => 28.3495,
      'ounces' => 28.3495,
      'oz' => 28.3495
    }.freeze

    WEIGHT_ORDER = %w[g oz lb kg].freeze

    METRIC_WEIGHT_UNITS = %w[g gram grams kg kilogram kilograms].freeze
    IMPERIAL_WEIGHT_UNITS = %w[oz ounce ounces lb lbs pound pounds].freeze
    METRIC_WEIGHT_ORDER = %w[g kg].freeze
    IMPERIAL_WEIGHT_ORDER = %w[oz lb].freeze

    WEIGHT_LADDER_FOR_UNIT = {
      'g' => METRIC_WEIGHT_ORDER,
      'gram' => METRIC_WEIGHT_ORDER,
      'grams' => METRIC_WEIGHT_ORDER,
      'kg' => METRIC_WEIGHT_ORDER,
      'kilogram' => METRIC_WEIGHT_ORDER,
      'kilograms' => METRIC_WEIGHT_ORDER,
      'oz' => IMPERIAL_WEIGHT_ORDER,
      'ounce' => IMPERIAL_WEIGHT_ORDER,
      'ounces' => IMPERIAL_WEIGHT_ORDER,
      'lb' => IMPERIAL_WEIGHT_ORDER,
      'lbs' => IMPERIAL_WEIGHT_ORDER,
      'pound' => IMPERIAL_WEIGHT_ORDER,
      'pounds' => IMPERIAL_WEIGHT_ORDER
    }.freeze
  end
end
