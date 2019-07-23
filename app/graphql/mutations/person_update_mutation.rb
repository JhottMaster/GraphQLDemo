module Mutations
  class PersonUpdateMutation < BaseMutation
    argument :id, ID, required: false
    argument :first_name, String, required: false
    argument :last_name, String, required: false
    argument :gender, Types::GenderEnum, required: false
    argument :age, Integer, required: false

    type Types::PersonType

    def resolve(id: nil, first_name: nil, last_name: nil, gender: nil, age: nil)
      person = id ? Person.find(id) : Person.new
      person.first_name = first_name.squish.capitalize if first_name
      person.last_name = last_name.squish.capitalize if last_name
      person.gender = gender if gender
      person.age = age if age
      person.save!

      person
    end
  end
end