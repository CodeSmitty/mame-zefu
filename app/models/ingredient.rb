require 'fractional'

class Ingredient
  # Non-persisted representation of a single parsed recipe ingredient line.
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :quantity, :string
  attribute :quantity_max, :string
  attribute :unit, :string
  attribute :quantity_secondary, :string
  attribute :unit_secondary, :string
  attribute :name, :string

  def quantity_range?
    quantity_max.present?
  end

  def scalable?
    quantity.present? || unit.present?
  end

  def scale(multiplier)
    return self unless scalable?

    apply_scaled_measurement(
      UnitFormatter.new(
        quantity: quantity.presence || '1',
        quantity_max:,
        unit:,
        scale: multiplier
      ).call
    )
    self
  end

  def formatted_quantity
    return if quantity.blank?
    return "#{humanize(quantity)} to #{humanize(quantity_max)}" if quantity_range?
    return humanize(quantity) unless formattable_quantity?

    humanize(formatted_measurement.quantity)
  end

  def formatted_unit
    return if quantity.blank?
    return unit if quantity_range? || !formattable_quantity?

    formatted_measurement.unit
  end

  # The remainder of a compound measurement, e.g. "+ 2 tbsp" for a total of
  # 1 3/4 c + 2 tbsp, or nil when the amount fits in a single unit.
  def formatted_secondary_measurement
    return if quantity.blank? || quantity_range? || !formattable_quantity?

    secondary_quantity = formatted_measurement.quantity_secondary
    return if secondary_quantity.blank?

    "+ #{humanize(secondary_quantity)} #{formatted_measurement.unit_secondary}"
  end

  def description
    return name if quantity.blank?

    [formatted_quantity, formatted_unit, formatted_secondary_measurement, name].compact_blank.join(' ')
  end
  alias to_s description

  private

  def apply_scaled_measurement(result)
    self.quantity = result.quantity
    self.quantity_max = result.quantity_max
    self.unit = result.unit
    self.quantity_secondary = result.quantity_secondary
    self.unit_secondary = result.unit_secondary
    # Reuse this result (it already reflects the requested scale) instead of
    # recomputing from the narrowed primary quantity/unit, which would lose
    # any compound remainder.
    @formatted_measurement = result
  end

  def humanize(value)
    Fractional.new(value, to_human: true).to_s(mixed_number: true)
  rescue StandardError
    value.to_s
  end

  def formatted_measurement
    @formatted_measurement ||= UnitFormatter.new(quantity:, unit:).call
  end

  def formattable_quantity?
    Rational(quantity)
    true
  rescue ArgumentError, TypeError, ZeroDivisionError
    false
  end
end
