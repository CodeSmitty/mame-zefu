# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Recipes::Import::RecipeKeeper do
  subject(:import) { described_class.new(document) }

  let(:document) { Nokogiri::HTML(html) }

  describe '#recipe_name' do
    let(:html) do
      <<-HTML
      <table>
        <tr>
          <td style="vertical-align:top">
            <h2 itemprop="name">#{recipe_name}</h2>
          </td>
        </tr>
      </table>
      HTML
    end
    let(:recipe_name) { 'My Cake' }

    it 'extracts the recipe name' do
      expect(import.recipe_name).to eq(recipe_name)
    end
  end

  describe '#recipe_yield' do
    let(:html) do
      <<-HTML
      <table>
        <tr>
          <td style="vertical-align:top">
            <div>
              Serving size: <span itemprop="recipeYield">#{recipe_yield}</span>
            </div>
          </td>
        </tr>
      </table>
      HTML
    end
    let(:recipe_yield) { '6 servings' }

    it 'extracts the recipe yield' do
      expect(import.recipe_yield).to eq(recipe_yield)
    end
  end

  describe '#recipe_prep_time' do
    let(:html) do
      <<-HTML
      <table>
        <tr>
          <td style="vertical-align:top">
            <div>
              Preparation time: <span>#{recipe_prep_time}</span>
              <meta content="PT10M" itemprop="prepTime">
            </div>
          </td>
        </tr>
      </table>
      HTML
    end
    let(:recipe_prep_time) { '10 mins' }

    it 'extracts the recipe prep time' do
      expect(import.recipe_prep_time).to eq(recipe_prep_time)
    end
  end

  describe '#recipe_cook_time' do
    let(:html) do
      <<-HTML
      <table>
        <tr>
          <td style="vertical-align:top">
            <div>
              Cooking time: <span>#{recipe_cook_time}</span>
              <meta content="PT30M" itemprop="cookTime">
            </div>
          </td>
        </tr>
      </table>
      HTML
    end
    let(:recipe_cook_time) { '30 mins' }

    it 'extracts the recipe cook time' do
      expect(import.recipe_cook_time).to eq(recipe_cook_time)
    end
  end

  describe '#recipe_ingredients' do
    let(:html) do
      <<-HTML
      <table>
        <tr>
          <td style="vertical-align:top;width:250px">
            <h3>Ingredients</h3>
            <div class="recipe-ingredients" itemprop="recipeIngredients">
              #{recipe_ingredients}
            </div>
          </td>
        </tr>
      </table>
      HTML
    end
    let(:recipe_ingredients) { "  \n  2c flour  \n  1c sugar  \n  " }

    it 'extracts and trims the recipe ingredients' do
      expect(import.recipe_ingredients).to eq("2c flour\n1c sugar")
    end
  end

  describe '#recipe_directions' do
    let(:html) do
      <<-HTML
      <table>
        <tr>
          <td style="vertical-align:top">
            <h3>Directions</h3>
            <div itemprop="recipeDirections">
              #{recipe_directions}
            </div>
          </td>
        </tr>
      </table>
      HTML
    end
    let(:recipe_directions) { "  \n  Mix ingredients.  \n  Bake at 350F.  \n  " }

    it 'extracts and trims the recipe directions' do
      expect(import.recipe_directions).to eq("Mix ingredients.\nBake at 350F.")
    end
  end

  describe '#recipe_notes' do
    let(:html) do
      <<-HTML
      <div class="recipe-notes" itemprop="recipeNotes">
        #{recipe_notes}
      </div>
      HTML
    end
    let(:recipe_notes) { "  \n  This is a family recipe.  \n  " }

    it 'extracts and trims the recipe notes' do
      expect(import.recipe_notes).to eq('This is a family recipe.')
    end
  end

  describe '#recipe_rating' do
    let(:html) do
      <<-HTML
      <meta content="#{recipe_rating}" itemprop="recipeRating">
      HTML
    end
    let(:recipe_rating) { '5' }

    it 'extracts the recipe rating' do
      expect(import.recipe_rating).to eq(recipe_rating)
    end
  end

  describe '#recipe_is_favorite' do
    let(:html) do
      <<-HTML
      <meta content="#{recipe_is_favorite ? 'True' : 'False'}" itemprop="recipeIsFavourite">
      HTML
    end
    let(:recipe_is_favorite) { true }

    it 'extracts whether the recipe is a favorite' do
      expect(import.recipe_is_favorite).to eq(recipe_is_favorite)
    end
  end

  describe '#recipe_catgory_names' do
    let(:html) do
      <<-HTML
      <table>
        <tr>
          <td style="vertical-align:top">
            <div>
              Courses: <span itemprop="recipeCourse">#{recipe_courses[0]}</span><span>, #{recipe_courses[1]}</span>
              <meta content="#{recipe_courses[1]}" itemprop="recipeCourse">
            </div>
            <div>
              Categories: <span>#{recipe_categories.join(', ')}</span>
              <meta content="#{recipe_categories[0]}" itemprop="recipeCategory">
              <meta content="#{recipe_categories[1]}" itemprop="recipeCategory">
            </div>
            <div>
              Collections: <span>#{recipe_collections.join(', ')}</span>
              <meta content="#{recipe_collections[0]}" itemprop="recipeCollection">
              <meta content="#{recipe_collections[1]}" itemprop="recipeCollection">
            </div>
          </td>
        </tr>
      </table>
      HTML
    end
    let(:recipe_courses) { %w[Dessert Snack] }
    let(:recipe_categories) { %w[Baking Cake] }
    let(:recipe_collections) { %w[Holiday Favorites] }

    it 'extracts the recipe category names' do
      expect(import.recipe_category_names).to eq(recipe_courses + recipe_categories + recipe_collections)
    end
  end

  describe '#recipe_source' do
    let(:html) do
      <<-HTML
      <table>
        <tr>
          <td style="vertical-align:top">
            <div>
              Source: <span itemprop="recipeSource"><a href="#{recipe_source}">Link Text</a></span>
            </div>
          </td>
        </tr>
      </table>
      HTML
    end
    let(:recipe_source) { 'https://example.com/recipe' }

    it 'extracts the recipe source URL' do
      expect(import.recipe_source).to eq(recipe_source)
    end
  end

  describe '#recipe_image_src' do
    let(:html) do
      <<-HTML
      <div class="recipe-photos-div"><img src="#{recipe_image_src}" class="recipe-photos" itemprop=photo0 /></div>
      HTML
    end
    let(:recipe_image_src) { 'images/cake.jpg' }

    it 'extracts the recipe image src' do
      expect(import.recipe_image_src).to eq(recipe_image_src)
    end
  end
end
