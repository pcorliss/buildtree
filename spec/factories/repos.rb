# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :repo do
    service "github"
    organization "bar"
    name "buzz"
  end

  factory :github_repo, class: Repo do
    service "github"
    organization "bkochendorfer"
    name "BuddyTube"
  end

  factory :private_key_repo, class: Repo do
    service "github"
    organization "pcorliss"
    name "design_patterns"
    private_key File.read('spec/fixtures/sample_key')
  end
end
