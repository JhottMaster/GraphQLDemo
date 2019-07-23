module Types
  class MutationType < Types::BaseObject
    field :person_update, "Allows creating or updating a person", mutation: Mutations::PersonUpdateMutation
  end
end
