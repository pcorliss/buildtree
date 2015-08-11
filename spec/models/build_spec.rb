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
end
