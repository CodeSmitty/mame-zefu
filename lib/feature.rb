class Feature
  NAMES = %i[recipe_extraction].freeze

  def self.sync_features
    features = NAMES.flat_map { |name| [name, :"#{name}_disabled"] }
    existing = Flipper.features.map(&:key).map(&:to_sym)
    create = features - existing
    delete = existing - features

    delete.each do |feature_name|
      Flipper.remove(feature_name)
    end

    create.each do |feature_name|
      Flipper.add(feature_name)
    end
  end

  NAMES.each do |feature_name|
    define_singleton_method("#{feature_name}_enabled?") do |actor|
      Flipper.enabled?(feature_name, actor) && !Flipper.enabled?("#{feature_name}_disabled", actor)
    end
  end
end
