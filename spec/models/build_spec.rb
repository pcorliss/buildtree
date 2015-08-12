require 'rails_helper'

describe Build do
  let(:build) { FactoryGirl.build(:build, repo: nil) }

  describe "#short_sha" do
    it "returns a 7 char sha" do
      expect(build.short_sha).to eq("ffcaf39")
    end

    it "returns nil if there is no sha" do
      build.sha = nil
      expect(build.short_sha).to be_nil
    end
  end

  describe "#enqueue!" do
    it "should enqueue a build job" do
      expect_any_instance_of(BuildJob).to receive(:perform)
      build.enqueue!
    end
  end

  describe "#self.new_from_config" do
    shared_examples "configuring a build" do
      it "returns a build object"
      it "sets the parent"
      it "sets the top_parent from the parent"
      it "sets the env as a json string"
      it "sets the parallel boolean"
    end

    context "sub project" do
      include_examples "configuring a build"
      it "sets the repo from the parent"
      it "sets the branch from the parent"
      it "sets the sha from the parent"
      it "sets the sub project path"
    end

    context "non-sub project" do
      include_examples "configuring a build"
      it "sets the repo from the passed values"
      it "sets the branch from the passed values"
      it "doesn't set the sub project path"
    end
  end
end
