FactoryGirl.define do
  factory :post do
    user
    title { Faker::Lorem.sentence }
    content { Faker::Lorem.paragraph }
  end
end
