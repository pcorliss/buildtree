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

  describe "#overall_status" do
    let(:build_error) { FactoryGirl.build(:build, repo: nil, status: 'error') }
    let(:build_failure) { FactoryGirl.build(:build, repo: nil, status: 'failure') }
    let(:build_pending) { FactoryGirl.build(:build, repo: nil, status: 'pending') }
    let(:build_queued) { FactoryGirl.build(:build, repo: nil, status: 'queued') }
    let(:build_success) { FactoryGirl.build(:build, repo: nil, status: 'success') }
    let(:builds) { [build_error, build_failure, build_pending, build_queued, build_success] }


    it "returns the current build status if there are no children" do
      expect(builds).to_not be_empty
      builds.each do |build|
        expect(build.children).to be_empty
        expect(build.overall_status).to eq(build.status)
      end
    end

    context "child_builds" do
      before do
        last_build = nil
        builds.each do |build|
          if last_build
            last_build.children << build
          end
          last_build = build
        end
      end

      it "returns error if one of the children errored" do
        expect(builds.first.overall_status).to eq('error')
      end

      it "returns failure if one of the children failed but no errors" do
        builds.reject! { |b| b.error? }
        expect(builds.first.overall_status).to eq('failure')
      end

      it "returns pending if one of the children pending but no fail or errors" do
        builds.reject! { |b| b.error? || b.failure? }
        expect(builds.first.overall_status).to eq('pending')
      end

      it "returns queued if one of the children queued but no fail or errors or pending" do
        builds.reject! { |b| b.error? || b.failure? || b.pending? }
        expect(builds.first.overall_status).to eq('queued')
      end

      it "returns success if all of the children are successful" do
        builds.reject! { |b| b.error? || b.failure? || b.pending? || b.queued? }
        expect(builds.first.overall_status).to eq('success')
      end
    end
  end

  describe "#children_status" do
    let(:build_error) { FactoryGirl.build(:build, repo: nil, status: 'error') }
    let(:build_failure) { FactoryGirl.build(:build, repo: nil, status: 'failure') }
    let(:build_pending) { FactoryGirl.build(:build, repo: nil, status: 'pending') }
    let(:build_queued) { FactoryGirl.build(:build, repo: nil, status: 'queued') }
    let(:build_success) { FactoryGirl.build(:build, repo: nil, status: 'success') }
    let(:builds) { [build_error, build_failure, build_pending, build_queued, build_success] }

    it "returns a map of all immediate child statuses" do
      build.children = builds
      expect(build.children_statuses).to eq(%w(
        error
        failure
        pending
        queued
        success
      ))
    end
  end

  describe "#self.new_from_config" do
    let(:repo) { FactoryGirl.build(:repo) }
    let(:top_parent) { FactoryGirl.build(:build, repo: repo) }
    let(:parent) { FactoryGirl.build(:build, repo: repo, parent: top_parent, top_parent: top_parent) }
    let(:build) { build = Build.new_from_config(config, parent) }

    shared_examples "configuring a build" do
      it "returns a build object" do
        expect(build).to be_a(Build)
      end

      it "sets the parent" do
        expect(build.parent).to eq(parent)
      end

      it "sets the top_parent from the parent" do
        expect(build.top_parent).to eq(top_parent)
      end

      it "sets the env as a json string" do
        build_env = JSON.parse(build.env)
        expect(build_env['PARENT_SHA']).to eq('a'*40)
        expect(build_env['PARENT_BRANCH']).to eq('master')
      end

      it "sets the parallel boolean" do
        expect(build.parallel).to be_truthy
      end
    end

    context "sub project" do
      let(:config) {Hashie::Mash.new(
        env: {
          'PARENT_SHA' => "a"*40,
          'PARENT_BRANCH' => 'master'
        },
        branch: 'foo',
        sub_project_path: 'some/path/.bt.yml',
        parallel: true,
      )}

      include_examples "configuring a build"

      it "sets the repo from the parent" do
        expect(build.repo).to eq(repo)
      end

      it "sets the branch from the parent" do
        expect(build.branch).to eq('foo')
      end

      it "sets the sha from the parent" do
        parent.sha = 'b'*40
        expect(build.sha).to eq('b'*40)
      end

      it "sets the sub project path" do
        expect(build.sub_project_path).to eq('some/path/.bt.yml')
      end
    end

    context "non-sub project" do
      let(:project_params) {{
        service: 'github',
        organization: 'fubar',
        name: 'barfoo',
      }}
      let(:project_repo) { FactoryGirl.create(:repo, project_params) }
      let(:config) {Hashie::Mash.new(
        env: {
          'PARENT_SHA' => "a"*40,
          'PARENT_BRANCH' => 'master'
        },
        branch: 'foo',
        repo: project_params,
        parallel: true,
      )}

      before do
        project_repo
      end

      include_examples "configuring a build"

      it "sets the repo from the passed values" do
        expect(build.repo).to eq(project_repo)
      end

      it "sets the branch from the passed values" do
        expect(build.branch).to eq('foo')
      end

      it "doesn't set the sub project path" do
        expect(build.sub_project_path).to be_nil
      end

      it "sets the sha to nil" do
        expect(build.sha).to be_nil
      end
    end
  end
end
