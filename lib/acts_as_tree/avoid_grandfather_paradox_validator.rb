# lib/acts_as_tree/avoid_grandfather_paradox_validator.rb

class AvoidGrandfatherParadoxValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    parent = record.class.find(value)
    ancestor_ids = parent.ancestors.map(&:id)
    record.errors[attribute] << "record cannot be its own descendant" if ancestor_ids.include? record.id
  rescue ActiveRecord::RecordNotFound => error
    # no parent record found, so (probably) okay?
  end # method validate_each
end # validator AvoidGrandfatherParadoxValidator
