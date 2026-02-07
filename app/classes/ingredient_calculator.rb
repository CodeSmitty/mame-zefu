class IngredientCalculator
    attr_accessor :recipe

    FRACTION_MAP = {
    '½' => '1/2', '⅓' => '1/3', '⅔' => '2/3',
    '¼' => '1/4', '¾' => '3/4',
    '⅕' => '1/5', '⅖' => '2/5', '⅗' => '3/5', '⅘' => '4/5',
    '⅙' => '1/6', '⅚' => '5/6',
    '⅐' => '1/7',
    '⅛' => '1/8', '⅜' => '3/8', '⅝' => '5/8', '⅞' => '7/8',
    '⅑' => '1/9',
    '⅒' => '1/10',
  }.freeze

    def ingredientList

        ingredients_text = recipe.ingredients.to_s
        ingredients = ingredients_text.split(/r?\n/).map(&:strip).reject(&:empty?)

        ingredients.map do |ingredient|
            parse_ingredients(ingredient)
        end
    end

    def parse_ingredients(ingredient)
        normalized = ingredient.to_s.dup

        FRACTION_MAP.each do |unicode, replacement|
            normalized.gsub(unicode, replacement)
        end

        quantity = nil
        if match = normalized.match(/^\s*(\d+(?:\.\d+)?)?\s*(\d+\s*\/\s*\d+)?/)
            whole_number = match[1]
            fraction_number = match[2]
            
            quantity = if whole_number && fraction_number
                "#{whole_number} #{fraction_number.gsub(' ', '')}"
            elsif whole_number
                whole_number
            elsif fraction_number
                fraction_number.gsub(' ', '')
            else
                nil
            end
        else
            quantity = nil
        end

        unit = nil

        if quantity
            remaining = normalized.sub(/^\s*#{Regexp.escape(quantity.to_s)}/, '')
            unit_match = remaining.downcase.match(/\s*(cup|teaspoon|tablespoon|tsp|tbsp|oz|ounce|pound|lb|gram|g|ml|liter|l|pint|quart|gallon)/)
            unit = unit_match[1] if unit_match
        end

        {
            original: ingredient,
            quantity: quantity,
            unit: unit
        }
    end

    def parsed_ingredients
        results = ingredientList
        puts "Parsed #{results.size} ingredients:"
        puts "-" * 50
    
        results.each_with_index do |result, i|
        puts "#{i + 1}. #{result[:original]}"
        puts "   → Quantity: #{result[:quantity] || '(none)'}"
        puts "   → Unit: #{result[:unit] || '(none)'}"
        puts
    end
  end
end