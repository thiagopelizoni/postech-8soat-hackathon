class DateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.present? && value > 16.years.ago.to_date
      record.errors.add(attribute, "deve ser de no mínimo 16 anos de idade")
    end
  end
end