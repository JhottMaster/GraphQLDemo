module Types
  class QueryType < Types::BaseObject
    field :people, [PersonType], null: false, description: "All people in our database"
    
    def people
      Person.all
    end
  end
end
