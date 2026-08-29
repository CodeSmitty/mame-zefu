require 'fractional'

class Ingredient
  # Non-persisted representation of a single parsed recipe ingredient line.
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :quantity, :string
  attribute :quantity_max, :string
  attribute :unit, :string
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

  def description
    return name if quantity.blank?

    [formatted_quantity, formatted_unit, name].compact_blank.join(' ')
  end
  alias to_s description

  private

  def apply_scaled_measurement(result)
    self.quantity = result.quantity
    self.quantity_max = result.quantity_max
    self.unit = result.unit
    @formatted_measurement = nil
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
