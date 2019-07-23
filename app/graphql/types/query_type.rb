module Types
  class QueryType < Types::BaseObject
    field :people, [PersonType], null: false, description: "All people in our database" do
      argument :last_name, String, required: false
      argument :gender, [GenderEnum], required: false
    end
    
    def people(last_name: nil, gender: nil)
      people = Person.all
      people = Person.select { |p| p.last_name == last_name } if last_name
      people = Person.select { |p| p.gender.in?(gender) } if Array.wrap(gender).any?
      people
    end
  end
end
