# == Schema Information
#
# Table name: triples
#
#  id                   :integer          not null, primary key
#  dataset_id           :integer
#  resource_class       :string(255)
#  resource_id          :integer
#  resource_text        :string(255)
#  predicate            :string(255)
#  object_type          :string(255)
#  object_class         :string(255)
#  object_resource_id   :integer
#  object_resource_text :string(255)
#  realm                :string(255)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#

require 'spec_helper'

describe Triple do
  pending "add some examples to (or delete) #{__FILE__}"
end
