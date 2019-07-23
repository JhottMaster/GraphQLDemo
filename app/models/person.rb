# == Schema Information
#
# Table name: people
#
#  id         :bigint           not null, primary key
#  parent_id  :bigint
#  first_name :string
#  last_name  :string
#  age        :integer
#  gender     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Person < ApplicationRecord
  belongs_to :parent, class_name: 'Person', optional: true
  has_many :children, class_name: 'Person', foreign_key: :parent_id, inverse_of: :parent
end
