FactoryGirl.define do
  factory :build_log do
    build
    text "[]"
    cmd "whoami"
    exit_code 0
  end
end
