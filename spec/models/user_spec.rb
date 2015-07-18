require 'spec_helper'

describe User do
  context "validations" do
    let(:valid_attrs)   { FactoryGirl.attributes_for(:user) }
    let(:valid_user)    { User.new(valid_attrs) }
    let(:invalid_user)  { valid_user }

    it "is valid" do
      expect(valid_user).to be_valid
    end

    it "requires a uid" do
      invalid_user.uid = ''
      expect(invalid_user).to_not be_valid
    end

    it "requires a provider" do
      invalid_user.provider = ''
      expect(invalid_user).to_not be_valid
    end
  end

  describe "#find_or_create_from_auth_hash" do
    shared_examples "finding and creating from auth_hash" do
      it "finds an existing user by the auth hash" do
        user1 = User.find_or_create_from_auth_hash(callback)
        user2 = User.find_or_create_from_auth_hash(callback)
        expect(user1).to be_a(User)
        expect(user2).to be_a(User)
        expect(user1).to be_valid
        expect(user2).to be_valid
        expect(user1).to eq(user2)
      end

      it "updates a users information if it changes" do
        user1 = User.find_or_create_from_auth_hash(callback)
        user1.token = 'different_token'
        user1.save
        user2 = User.find_or_create_from_auth_hash(callback)
        expect(user2.token).to_not eq(user1.token)
        expect(user2.token).to eq(expected_token)
      end

      it "creates a new user from the auth hash" do
        user = nil
        expect do
          user = User.find_or_create_from_auth_hash(callback)
        end.to change{ User.count }.by(1)

        expect(user.name).to eq('Philip Corliss')
        expect(user.email).to eq('pcorliss@50projects.com')
        expect(user.provider).to eq(provider)
        expect(user.uid).to eq(expected_uid)
        expect(user.avatar).to be_present
        expect(user.token).to eq(expected_token)
        expect(user.secret).to eq(expected_secret)
      end
    end

    #context "bitbucket" do
      #let(:provider) { 'bitbucket' }
      #let(:callback) { JSON.parse File.read("spec/fixtures/#{provider}_callback.json")}
      #let(:expected_uid) { 'pcorliss' }
      #let(:expected_token) { 'AAAAAAAAAAAAAAAAAA' }
      #let(:expected_secret) { 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB' }


      #include_examples "finding and creating from auth_hash"
    #end

    context "github" do
      let(:provider) { 'github' }
      let(:callback) { JSON.parse File.read('spec/fixtures/github_callback.json')}
      let(:expected_uid) { '141914' }
      let(:expected_token) { '12345abcde12345abcde12345abcde12345abcde' }
      let(:expected_secret) { nil }

      include_examples "finding and creating from auth_hash"
    end
  end

  context "#slug" do
    it "returns the slug composed of the provider and uid" do
      user = FactoryGirl.build(:user)
      expect(user.uid).to be_present
      expect(user.slug).to eq("github_#{user.uid}")
    end
  end
end
