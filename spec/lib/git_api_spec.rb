#require 'spec_helper'
require './lib/git_api.rb'
require 'yaml'

describe GitApi do
  let(:github_user)     { Struct::User.new('abc123', nil, 'github') }

  before(:all) do
    Struct.new("User", :token, :secret, :provider) # This likely pollutes the global scope
  end

  describe "#initialize" do
    it "creates a github connection based on service " do
      api = GitApi.new(github_user)
      expect(api.source).to be_a(Octokit::Client)
      expect(api.service).to eq(:github)
    end
  end

  describe "#add_new_deploy_key" do
    let(:pub_key) { 'abc123' }
    let(:priv_key) { 'efg456' }
    let(:api) { GitApi.new(github_user) }

    before do
      allow_any_instance_of(SSHKey).to receive(:ssh_public_key).and_return(pub_key)
      allow_any_instance_of(SSHKey).to receive(:encrypted_private_key).and_return(priv_key)
      allow_any_instance_of(Octokit::Client).to receive(:add_deploy_key)
    end

    it "raises if the SSH_KEY_SIZE is not set" do
      ENV['SSH_KEY_SIZE'] = nil
      expect do
        api.add_new_deploy_key('foo', 'bar')
      end.to raise_error(StandardError)
    end

    it "raises if the SSH_PASSPHRASE is not set" do
      ENV['SSH_PASSPHRASE'] = nil
      expect do
        api.add_new_deploy_key('foo', 'bar')
      end.to raise_error(StandardError)
    end

    shared_examples "adding a key" do
      it "returns an encrypted private key for storage" do
        expect(api.add_new_deploy_key('foo', 'bar')).to eq(priv_key)
      end
    end

    context "github" do
      let(:api) { GitApi.new(github_user) }

      it "git client receives a call" do
        expect_any_instance_of(Octokit::Client).to receive(:add_deploy_key).with('foo/bar', 'BuildTree', pub_key)

        api.add_new_deploy_key('foo', 'bar')
      end

      include_examples "adding a key"
    end
  end

  describe "#deploy_key_exists?" do
    let(:public_key) { File.read('spec/fixtures/sample_key.pub') }
    let(:fingerprint) { '72:16:2d:8f:b1:a3:a5:db:1d:ed:f8:b3:05:e8:94:6c' }

    shared_examples "checking a key" do
      let(:invalid_fingerprint) { 'invalid_fingerprint' }

      it "returns true if the key exists" do
        expect(api.deploy_key_exists?('foo', 'bar', fingerprint)).to be_truthy
      end

      it "returns false if the key does not exist" do
        expect(api.deploy_key_exists?('foo', 'bar', invalid_fingerprint)).to be_falsy
      end
    end

    context "github" do
      let(:api) { GitApi.new(github_user) }

      before do
        # This actually comes back as a Sawyer resource,
        # Setting via HashieMash for convenience
        allow_any_instance_of(Octokit::Client).to receive(:deploy_keys).with('foo/bar').and_return([
          Hashie::Mash.new({
            :id=> 8906688,
            :key=> public_key,
            :url=>"https://api.github.com/user/keys/8906688",
            :title=>"temp",
            :verified=>true
          })
        ])
      end

      include_examples "checking a key"
    end
  end

  describe "#repos" do
    let(:octokit_mock)           { double(Octokit::Client, repos: mock_github_repos) }
    let(:mock_github_repos)      do
      repos = YAML.load_file "spec/fixtures/github_repos.yml"
      repos.each do |repo|
        repo.instance_variable_set("@_metaclass", Sawyer::Resource)
        repo.owner.instance_variable_set("@_metaclass", Sawyer::Resource)
      end
    end

    context "github" do
      let(:user) { github_user }
      before do
        allow(Octokit::Client).to receive_messages(new: octokit_mock)
      end

      it "returns a list of hashes" do
        api = GitApi.new(user)
        repos = api.repos
        expect(repos.count).to eq(2)
        expect(repos.first.name).to eq('BuddyTube')
        expect(repos.first.owner).to eq('bkochendorfer')
        expect(repos.first.service).to eq('github')
        expect(repos.first.private).to eq(false)
      end
    end
  end

  context "web hooks" do
    let(:hooks_fixture) do
      hooks = YAML.load_file "spec/fixtures/hooks.yaml"
      hooks.each do |hook|
        hook.instance_variable_set("@_metaclass", Sawyer::Resource)
        hook.config.instance_variable_set("@_metaclass", Sawyer::Resource)
      end
    end

    before do
      allow_any_instance_of(Octokit::Client).to receive(:create_hook)
      allow_any_instance_of(Octokit::Client).to receive(:hooks)
    end

    describe "#add_new_webhook" do
      let(:api) { GitApi.new(github_user) }

      it "adds a new webhook" do
        expect_any_instance_of(Octokit::Client).to receive(:create_hook)
        api.add_new_webhook("foo", "bar", "http://example.com/webhook")
      end
    end

    describe "#webhook_exists?" do
      let(:api) { GitApi.new(github_user) }

      it "checks for the existance of a webhook" do
        expect_any_instance_of(Octokit::Client).to receive(:hooks).with("foo/bar").at_least(:once).and_return(hooks_fixture)
        api.add_new_webhook("foo", "bar", "http://example.com/webhook")
        expect(api.webhook_exists?("foo", "bar", "http://example.com/webhook")).to be_truthy
        expect(api.webhook_exists?("foo", "bar", "http://example.com/missing")).to be_falsey
      end
    end
  end

  context "#default_branch" do
    let(:repository_fixture) do
      repository = YAML.load_file "spec/fixtures/github_repository.yml"
      repository.instance_variable_set("@_metaclass", Sawyer::Resource)
      repository
    end

    let(:api) { GitApi.new(github_user) }

    it "returns the default branch" do
      expect_any_instance_of(Octokit::Client).to receive(:repository).with("foo/bar").and_return(repository_fixture)
      expect(api.default_branch("foo/bar")).to eq('master')
    end
  end

  context "#head_sha" do
    let(:ref_fixture) do
      ref = YAML.load_file "spec/fixtures/github_ref.yml"
      ref.instance_variable_set("@_metaclass", Sawyer::Resource)
      ref.object.instance_variable_set("@_metaclass", Sawyer::Resource)
      ref
    end

    let(:api) { GitApi.new(github_user) }

    it "returns the sha on the default branch" do
      expect_any_instance_of(Octokit::Client).to receive(:ref).with("foo/bar", "heads/master").and_return(ref_fixture)
      expect(api.head_sha("foo/bar", "master")).to eq('d82d4aaaf1ad77e5e41c6baac143817f89f48506')
    end
  end

  context "#set_status" do
    let(:api) { GitApi.new(github_user) }

    it "sets the status of the repository" do
      expect(api.source).to receive(:create_status).with(
        "foo/bar",
        "a"*40,
        "success",
        context: "BuildTree",
        target_url: "http://example.com/foo/bar",
        description: "Build Completed Successfully",
      )
      api.set_status(
        repo: "foo/bar",
        sha: "a"*40,
        status: "success",
        context: "BuildTree",
        target_url: "http://example.com/foo/bar",
        description: "Build Completed Successfully",
      )
    end
  end
end
