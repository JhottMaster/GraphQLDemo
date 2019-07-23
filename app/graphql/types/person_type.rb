module Types
  class PersonType < BaseObject
    field :id, ID, null: false
    field :first_name, String, null: false
    field :last_name, String, null: false
    field :age, Integer, null: false
    
    field :full_name, String, null: false
    def full_name
      "#{object.first_name} #{object.last_name}"
    end

    field :parent, PersonType, null: true
    field :children, [PersonType], null: false
  end
end