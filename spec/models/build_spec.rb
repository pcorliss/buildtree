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
    let(:repo) { FactoryGirl.build(:repo) }
    let(:top_parent) { FactoryGirl.build(:build, repo: repo) }
    let(:parent) { FactoryGirl.build(:build, repo: repo, parent: top_parent, top_parent: top_parent) }

    shared_examples "configuring a build" do
      it "returns a build object" do
        build = Build.new_from_config(config, parent)
        expect(build).to be_a(Build)
      end

      it "sets the parent" do
        build = Build.new_from_config(config, parent)
        expect(build.parent).to eq(parent)
      end

      it "sets the top_parent from the parent" do
        build = Build.new_from_config(config, parent)
        expect(build.top_parent).to eq(top_parent)
      end

      it "sets the env as a json string" do
        build = Build.new_from_config(config, parent)
        build_env = JSON.parse(build.env)
        expect(build_env['PARENT_SHA']).to eq('a'*40)
        expect(build_env['PARENT_BRANCH']).to eq('master')
      end

      it "sets the parallel boolean" do
        build = Build.new_from_config(config, parent)
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
        build = Build.new_from_config(config, parent)
        expect(build.repo).to eq(repo)
      end

      it "sets the branch from the parent" do
        build = Build.new_from_config(config, parent)
        expect(build.branch).to eq('foo')
      end

      it "sets the sha from the parent" do
        parent.sha = 'b'*40
        build = Build.new_from_config(config, parent)
        expect(build.sha).to eq('b'*40)
      end

      it "sets the sub project path" do
        build = Build.new_from_config(config, parent)
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
        build = Build.new_from_config(config, parent)
        expect(build.repo).to eq(project_repo)
      end

      it "sets the branch from the passed values" do
        build = Build.new_from_config(config, parent)
        expect(build.branch).to eq('foo')
      end

      it "doesn't set the sub project path" do
        build = Build.new_from_config(config, parent)
        expect(build.sub_project_path).to be_nil
      end
    end
  end
end
