FactoryGirl.define do
  factory :build do
    repo
    branch "master"
    sha 'ffcaf395a6bb110182d357cebb4b9b49e34b6394'
    status 1 # success
  end
end
