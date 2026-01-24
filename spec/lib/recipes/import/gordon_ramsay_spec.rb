# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Recipes::Import::GordonRamsay do
  subject(:import) { described_class.new(document) }

  let(:document) { Nokogiri::HTML(html) }

  describe '#recipe_name' do
    let(:html) do
      <<-HTML
        <section class="recipe-block-preview">
          <div class="hero-title-recipe">
            <h2>#{recipe_name}</h2>
          </div>
        </section>
      HTML
    end
    let(:recipe_name) { 'My Cake' }

    it 'extracts the recipe name' do
      expect(import.recipe_name).to eq(recipe_name)
    end
  end

  describe '#recipe_image_src' do
    let(:html) do
      <<-HTML
        <section class="recipe-block-preview">
          <div class="hero-image-recipe">
            <div class="imagegb">
              <img src="#{recipe_image_src}" />
            </div>
          </div>
        </section>
      HTML
    end
    let(:recipe_image_src) { 'images/cake.jpg' }

    it 'extracts the recipe image src' do
      expect(import.recipe_image_src).to eq("https://gordonramsay.com#{recipe_image_src}")
    end
  end

  describe '#recipe_yield' do
    let(:html) do
      <<-HTML
        <section class="recipe-block-preview">
          <article class="recipe-instructions">
            <div>
              <p>#{recipe_yield}</p>
            </div>
          </article>
        </section>
      HTML
    end
    let(:recipe_yield) { 'Serves 4' }

    it 'extracts the recipe yield' do
      expect(import.recipe_yield).to eq(recipe_yield)
    end
  end

  describe '#recipe_ingredients' do
    let(:html) do
      <<~HTML
        <section class="recipe-block-preview">
          <aside class="recipe-ingredients">
            <p class="recipe-division"><span>Cake:</span></p>
            <ul class="recipe-division">
              <li><span>2c flour</span></li>
              <li><span>1c sugar</span></li>
            </ul>
          </aside>
        </section>
      HTML
    end

    it 'extracts the recipe ingredients' do
      expect(import.recipe_ingredients).to eq("CAKE:\n2c flour\n1c sugar")
    end
  end

  describe '#recipe_directions' do
    let(:html) do
      <<-HTML
        <section class="recipe-block-preview">
          <article class="recipe-instructions">
            <div>
              <ol>
                <li>  Mix ingredients.  </li>
                <li>  Bake at 350F.  </li>
              </ol>
            </div>
          </article>
        </section>
      HTML
    end

    it 'extracts and trims the recipe directions' do
      expect(import.recipe_directions).to eq("Mix ingredients.\n\nBake at 350F.")
    end
  end
end
