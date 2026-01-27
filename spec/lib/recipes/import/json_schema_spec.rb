# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Recipes::Import::JsonSchema do
  subject(:import) { described_class.new(document) }

  let(:document) { Nokogiri::HTML(html) }
  let(:html) do
    <<~HTML
      <script type ="application/ld+json">[{
        "@context": "http://schema.org/",
        "@type": "Recipe",
        #{field_json}
      }]</script>
    HTML
  end

  context 'when recipe is nested' do
    let(:html) do
      <<~HTML
        <script type="application/ld+json">{
          "@context": "https://schema.org",
          "@graph": [
            {"@type": "Article"},
            {"@type": "Recipe"}
          ]
        }</script>
      HTML
    end

    it 'does not raise error' do
      expect { import }.not_to raise_error
    end

    it 'finds the recipe data' do
      expect(import.send(:recipe_json)).to eq({ '@type' => 'Recipe' })
    end
  end

  context 'when no recipe data is present' do
    let(:html) do
      <<~HTML
        <html><head></head><body></body></html>
      HTML
    end

    it 'raises NotFoundError' do
      expect { import }.to raise_error(Recipes::Import::JsonSchema::NotFoundError)
    end
  end

  describe '#recipe_name' do
    let(:field_json) do
      <<~JSON
        "name": "#{recipe_name}"
      JSON
    end
    let(:recipe_name) { 'My Cake' }

    it 'extracts the recipe name' do
      expect(import.recipe_name).to eq(recipe_name)
    end
  end

  describe '#recipe_image_src' do
    let(:field_json) do
      <<~JSON
        "image": [
          {
            "@type": "ImageObject",
            "url": "#{recipe_image_src}",
            "height": "1280",
            "width": "1280"
          }
        ]
      JSON
    end
    let(:recipe_image_src) { 'https://example.org/images/cake.jpg' }

    it 'extracts the recipe image src' do
      expect(import.recipe_image_src).to eq(recipe_image_src)
    end

    context 'when image is not a full url' do
      let(:field_json) do
        <<~JSON
          "image": [
            "/images/cake.jpg"
          ]
        JSON
      end

      it 'returns nil' do
        expect(import.recipe_image_src).to be_nil
      end
    end
  end

  describe '#recipe_yield' do
    let(:field_json) do
      <<~JSON
        "recipeYield": "#{recipe_yield}"
      JSON
    end
    let(:recipe_yield) { '6 servings' }

    it 'extracts the recipe yield' do
      expect(import.recipe_yield).to eq(recipe_yield)
    end
  end

  describe '#recipe_prep_time' do
    let(:field_json) do
      <<~JSON
        "prepTime": "PT10M"
      JSON
    end

    it 'extracts the recipe prep time' do
      expect(import.recipe_prep_time).to eq('10 minutes')
    end
  end

  describe '#recipe_cook_time' do
    let(:field_json) do
      <<~JSON
        "cookTime": "PT30M"
      JSON
    end

    it 'extracts the recipe cook time' do
      expect(import.recipe_cook_time).to eq('30 minutes')
    end
  end

  describe '#recipe_total_time' do
    let(:field_json) do
      <<~JSON
        "totalTime": "PT1H30M"
      JSON
    end

    it 'extracts the recipe total time' do
      expect(import.recipe_total_time).to eq('1 hour and 30 minutes')
    end
  end

  describe '#recipe_category_names' do
    let(:field_json) do
      <<~JSON
        "recipeCategory": "#{recipe_category}",
        "recipeCuisine": "#{recipe_cuisine}"
      JSON
    end
    let(:recipe_category) { 'Baking' }
    let(:recipe_cuisine) { 'French' }

    it 'extracts the recipe category names' do
      expect(import.recipe_category_names).to contain_exactly(recipe_cuisine, recipe_category)
    end
  end

  describe '#recipe_description' do
    let(:field_json) do
      <<~JSON
        "description": "#{recipe_description}"
      JSON
    end
    let(:recipe_description) { 'A delicious cake recipe' }

    it 'extracts the recipe description' do
      expect(import.recipe_description).to eq(recipe_description)
    end

    context 'when no description present' do
      let(:field_json) do
        <<~JSON
          "foo": "bar"
        JSON
      end

      it 'returns nil' do
        expect(import.recipe_description).to be_nil
      end
    end
  end

  describe '#recipe_ingredients' do
    let(:field_json) do
      <<~JSON
        "recipeIngredient": [
          "2c flour",
          "1c sugar"
        ]
      JSON
    end

    it 'extracts and trims the recipe ingredients' do
      expect(import.recipe_ingredients).to eq("2c flour\n1c sugar")
    end
  end

  describe '#recipe_directions' do
    let(:field_json) do
      <<~JSON
        "recipeInstructions": [
          {
            "@type": "HowToStep",
            "text": "Mix ingredients."
          },
          {
            "@type": "HowToStep",
            "text": "Bake at 350F."
          }
        ]
      JSON
    end

    it 'extracts and trims the recipe directions' do
      expect(import.recipe_directions).to eq("Mix ingredients.\n\nBake at 350F.")
    end

    context 'with sections' do
      let(:field_json) do
        <<~JSON
          "recipeInstructions": [
            {
              "@type": "HowToSection",
              "name": "Dough",
              "itemListElement": [
                {
                  "@type": "HowToStep",
                  "text": "Mix flour and water."
                }
              ]
            },
            {
              "@type": "HowToSection",
              "name": "Baking",
              "itemListElement": [
                {
                  "@type": "HowToStep",
                  "text": "Bake at 400F."
                }
              ]
            }
          ]
        JSON
      end

      it 'extracts sections in the recipe directions' do
        expect(import.recipe_directions).to eq("DOUGH\nMix flour and water.\n\nBAKING\nBake at 400F.")
      end
    end

    context 'when instructions are plain text' do
      let(:field_json) do
        <<~JSON
          "recipeInstructions": "#{recipe_instructions}"
        JSON
      end
      let(:recipe_instructions) { 'Just mix everything and bake.' }

      it 'handles plain text instructions' do
        expect(import.recipe_directions).to eq(recipe_instructions)
      end
    end
  end
end
