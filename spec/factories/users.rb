# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    name "Bob Smith"
    provider "github"
    sequence(:uid) { |n| n }
    sequence(:email) { |n| "bsmith#{n}@example.com" }
    avatar "https://avatars.githubusercontent.com/u/141914"
    token "abc123"
    secret "456fed"
  end
end
