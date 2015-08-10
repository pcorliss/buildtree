FactoryGirl.define do
  factory :build do
    repo
    branch "master"
    sha 'ffcaf395a6bb110182d357cebb4b9b49e34b6394'
    status 1 # success
    build_status 1 # build_success
  end
end
