module Types
  class QueryType < Types::BaseObject
    field :people, [PersonType], null: false, description: "All people in our database" do
      argument :last_name, String, required: false
    end
    
    def people(last_name: nil)
      people = Person.all
      people = Person.select { |p| p.last_name == last_name } if last_name
      people
    end
  end
end
