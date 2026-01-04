# frozen_string_literal: true

require 'zip'

module Recipes
  class Archive
    def initialize(user)
      @user = user
    end

    def generate # rubocop:disable Metrics/AbcSize , Metrics/MethodLength
      file = Tempfile.new(['recipes', '.zip'])
      file.binmode

      Zip::File.open(file.path, create: true) do |zip_file|
        recipes = []

        user.recipes.with_attached_image.each do |recipe|
          recipes << recipe.as_json(
            except: %i[id user_id created_at updated_at],
            include: { image: { only: [], methods: :filename } }
          )

          next unless recipe.image.attached?

          zip_file.get_output_stream("images/#{recipe.image.filename}") do |f|
            f.write recipe.image.download
          end
        end

        zip_file.get_output_stream('recipes.json') do |f|
          f.write JSON.pretty_generate(recipes)
        end
      end

      file
    end

    private

    attr_reader :user
  end
end
