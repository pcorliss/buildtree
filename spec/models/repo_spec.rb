require 'spec_helper'

describe Repo do
  describe "validations" do
    let(:valid_attrs) { FactoryGirl.attributes_for(:repo) }

    it "is valid" do
      expect(Repo.new(valid_attrs)).to be_valid
    end

    it "requires the presence of a service" do
      invalid_attrs = valid_attrs.clone
      invalid_attrs[:service] = ''
      expect(Repo.new(invalid_attrs)).to be_invalid
    end

    %w(
      github
    ).each do |valid_service|
      it "the #{valid_service} is valid" do
        valid_attrs[:service] = valid_service
        expect(Repo.new(valid_attrs)).to be_valid
      end
    end

    it "the 'foo' service is invalid" do
      invalid_attrs = valid_attrs.clone
      invalid_attrs[:service] = 'foo'
      expect(Repo.new(invalid_attrs)).to be_invalid
    end

    it "requires the presence of a organization" do
      invalid_attrs = valid_attrs.clone
      invalid_attrs[:organization] = ''
      expect(Repo.new(invalid_attrs)).to be_invalid
    end

    it "requires the presence of a name" do
      invalid_attrs = valid_attrs.clone
      invalid_attrs[:name] = ''
      expect(Repo.new(invalid_attrs)).to be_invalid
    end

    it "prevents the creation of repos with the same service, org, and name" do
      invalid_attrs = valid_attrs.clone
      repo = Repo.create(valid_attrs)
      expect(repo).to be_valid
      expect(Repo.new(invalid_attrs)).to be_invalid
    end
  end

  describe "#find_or_initialize_by_api" do
    context "github" do
      let(:repos) { YAML.load_file "spec/fixtures/git_api_github_repos.yml" }

      it "news a repo from the api response" do
        repo = Repo.find_or_initialize_by_api(repos.first)
        expect(repo.service).to eq('github')
        expect(repo.organization).to eq('bkochendorfer')
        expect(repo.name).to eq('BuddyTube')
        expect(repo.new_record?).to eq(true)
      end

      it "finds an existing repo" do
        # If we don't create two repos this test will always pass
        # find_or_init_by takes nil and returns first obj
        FactoryGirl.create(:repo)
        old_repo = Repo.create(
          service: 'github',
          organization: 'bkochendorfer',
          name: 'BuddyTube',
        )
        repo = Repo.find_or_initialize_by_api(repos.first)
        expect(repo).to eq(old_repo)
      end
    end
  end

  describe "#short_name" do
    it "generates a short name based on the org and name" do
      repo = FactoryGirl.build(:repo)
      expect(repo.short_name).to eq("bar/buzz")
    end
  end

  describe "#repo_url" do
    let(:sha) { "a"*40 }
    let(:file) { "foo/bar/buzz.rb" }

    context "github" do
      let(:repo) { FactoryGirl.build(:repo, service: 'github') }

      it "returns the correct url" do
        expect(repo.external_url).to eq('https://github.com/bar/buzz')
      end

      it "takes an optional sha arg" do
        expect(repo.external_url(sha)).to eq(
          "https://github.com/bar/buzz/tree/#{sha}"
        )
      end

      it "takes an optional file arg" do
        expect(repo.external_url(sha, file)).to eq(
          "https://github.com/bar/buzz/blob/#{sha}/#{file}"
        )
      end

      it "takes an optional line number arg" do
        expect(repo.external_url(sha, file, 1)).to eq(
          "https://github.com/bar/buzz/blob/#{sha}/#{file}#L1"
        )
      end
    end
  end
end
