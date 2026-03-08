# frozen_string_literal: true

module Recipes
  class Extraction
    class ResultStore
      CACHE_KEY_PREFIX = 'recipes:extraction'
      CACHE_TTL = 15.minutes
      RECIPE_FIELDS = %i[name yield prep_time cook_time total_time description ingredients directions].freeze

      def self.store(user:, recipe:)
        token = SecureRandom.urlsafe_base64(24)

        cache_store.write(
          cache_key(user:, token:),
          recipe_attributes(recipe),
          expires_in: CACHE_TTL
        )

        token
      end

      def self.fetch(user:, token:)
        key = cache_key(user:, token:)
        payload = cache_store.read(key)
        cache_store.delete(key)
        payload
      end

      def self.recipe_attributes(recipe)
        RECIPE_FIELDS.index_with { |field| recipe.public_send(field) }.merge(
          category_names: recipe.category_names
        )
      end
      private_class_method :recipe_attributes

      def self.cache_store
        return Rails.cache unless Rails.cache.is_a?(ActiveSupport::Cache::NullStore)

        @cache_store ||= ActiveSupport::Cache::MemoryStore.new
      end
      private_class_method :cache_store

      def self.cache_key(user:, token:)
        "#{CACHE_KEY_PREFIX}:#{user.id}:#{token}"
      end
      private_class_method :cache_key
    end
  end
end
