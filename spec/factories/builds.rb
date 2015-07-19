FactoryGirl.define do
  factory :build do
    repo
    branch "master"
    sha 'ffcaf395a6bb110182d357cebb4b9b49e34b6394'
    success true
  end
end
