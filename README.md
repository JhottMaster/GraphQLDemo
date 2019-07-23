# GraphQLDemo
GraphQL Demo Repo
# GraphQL Demo

This repo contains the GraphQL RoR project used in my GraphQL introduction presentation.

## "Pre-Demo" Setup Steps
The only steps not shown in the presentation was the very basic RoR project setup which can be done as follows:

1.) After installing PostgreSQL, create a PSQL database with a simple password:
```bash
psql
create role graph_demo with createdb login password 'password1';
exit
```

2.) Install rails, and create a new demo project using postgresql. Then create database & add graphql gem:

```bash
gem install rails
rails new graph_demo --database=postgresql

cd graph_demo/
bundle exec rails db:create
bundler add graphql
```

3.) Add the graphiql gem so we can navigate our schema:
Add gem `gem 'graphiql-rails'` under `group :development do` in gemlock file and run `bundler` to install

_The next steps are were we started off in our presentation._

## Demo Steps

Run rake task to setup & install graphql in your Rails project:
```bash
rails generate graphql:install
```
Now Graphiql is installed! Run `bundle exec puma` and navigate to http://localhost:3000/graphiql

### Database models

Let's build some database models we can use to demo using GraphQL to query and manipulate data.

We'll build a Person model that represents and individual family member. 
```bash
bundle add annotate
bundle exec rails generate model Person first_name:string last_name:string age:integer gender:string
```

To the migration, add a couple more things; a parent field and it's FK constraint:
```ruby
t.bigint :parent_id, null: true
```
```ruby
add_foreign_key :people, :people, column: :parent_id
```

To the model, add relationships:
```ruby
belongs_to :parent, class_name: 'Person', optional: true
has_many :children, class_name: 'Person', foreign_key: :parent_id, inverse_of: :parent
```
Now a person can have a parent and can have children. 

Run migration and update annotations:
```bash
bundle exec rake db:migrate
bundle exec annotate
```

### Adding Data

Let's add some data when can query. Open up rails console (`rails c`) and let's create some people:
```ruby
father = Person.create(first_name: "Adrian", last_name: "Aizpiri", age: 50, gender: 'male')
me = Person.create(first_name: "Pablo", last_name: "Aizpiri", age: 30, parent: father, gender: 'male')
brother = Person.create(first_name: "Jordan", last_name: "Aizpiri", age: 25, parent: father, gender: 'male')
sister = Person.create(first_name: "Elisabeth", last_name: "Aizpiri", age: 25, parent: father, gender: 'female')
```

### Graph Types

Okay- here we get to actually build out our first graph type. Notice the new folder structure that was created when we ran the `rails generate graphql:install` command: under `app` we now have a `graphql` folder with two additional folders underneath. Let's create the file `app/graphql/types/person_type.rb`:
```ruby
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
```

**Some things to notice:**
- Built-in data types
- Some scalars, some fields (parent/children vs first/lastname)
- Wrapping types (non-null wrapper, arrays)
- Field resolution

### Root Query Type
Let's check out what our graph looks like. Start puma if it's not running: `bundle exec puma`.

So we have a type, but notice you cannot see it in Graphiql. We need to add a type to the root query node to provide a path to the type we need, otherwise it will be an orphaned type. (The graph is traversed and this type never is reached) Let's add a field that returns all Person graph types from the root type:

```ruby
field :people, [PersonType], null: false, description: "All people in our database"
def people
  Person.all
end
```

Now we can query the graph. 

**How are queries served?**
Notice we're really just interacting with a controller when we make GraphQL queries. When we ran the `rails generate graphql:install` command a controller was created to service GraphQL queries. You can pull up the Chrome Dev tools when making a request and see it's an HTTP post being done against the GraphQL endpoint, with the POST body containing the query. It could also be configured to be a GET request. The response is a JSON document. It's very similar to REST in this regard.

### Filters
Let's do a quick example with filters, by modifying the query root type:
```ruby
field :people, [PersonType], null: false, description: "All people in our database" do
  argument :last_name, String, required: false
end

def people(last_name: nil)
  people = Person.all
  people = Person.select { |p| p.last_name == last_name } if last_name
  people
end
```

Let's add another person and test it:
rails c
```ruby
  father_in_law = Person.create(first_name: "Tom", last_name: "Koczynski", age: 53, parent: nil, gender: 'male')
```

### Graph Enums
Let's go a bit further and add a gender filter- but let's use an enum:
```ruby
module Types
  class GenderEnum < BaseEnum
    value 'MALE', 'Male', value: 'male'
    value 'FEMALE', 'Female', value: 'female'
    value 'NON_BINARY', 'Non-Binary', value: 'non_binary'
  end
end
```

Update Person graph type:
```ruby
  field :gender, GenderEnum, null: false
```

Update filter argument on people field in our root query type:
```ruby
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
```

### Mutations
So that's making requests which is great- but what about modifying data? Let's write a mutation. First, let's create a base mutation type just like all the other types we have and place that in the mutations folder. The only thing we are doing here is setting null to false, which allows the mutation field to return a null value. Mutations are fields, just like any other field. So they can be null or not null. Make sure to put this under `app/graph_types/mutations/`

```ruby
module Mutations
  # This class is used as a parent for all mutations, and it is the place to have common utilities 
  class BaseMutation < GraphQL::Schema::Mutation
    null false
  end
end
```

Now let's create our mutation for person object. Again, make sure to put this under `app/graph_types/mutations/`
```ruby
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
```

Let's add it to our mutations type:
```ruby
  field :person_update, "Allows creating or updating a person", mutation: Mutations::PersonUpdateMutation
```

Now we see it in Graphiql. Let's try it out and create a user:
```graphql
mutation {
  personUpdate(firstName: "Ryan", lastName: "Foster", age: 31, gender: MALE) {
    id
    fullName
    gender
    age
  }
}
```

Tada!


