FactoryGirl.define do
  factory :post do
    user
    category
    title { Faker::Lorem.sentence }
    content { Faker::Lorem.paragraph }
  end
end
