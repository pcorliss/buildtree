require 'rails_helper'

describe BuildJob do
  let(:repo) { FactoryGirl.build(:private_key_repo, users: [user]) }
  let(:build) { FactoryGirl.build(:build, repo: repo, status: 0) }
  let(:user) { FactoryGirl.build(:user) }
  let(:build_job) { BuildJob.new(build) }
  let(:tmpdir) { Dir.mktmpdir('build_job_spec') }
  let(:mock_process) { double(Process::Status, exitstatus: 0) }
  let(:fail_process) { double(Process::Status, exitstatus: 1) }
  let(:build_config_fixture) { File.read('spec/fixtures/build_config.yml') }

  describe "#perform" do
    before do
      allow(Dir).to receive(:mktmpdir).and_yield(tmpdir)
      allow(build_job).to receive(:system_cmd).and_return(mock_process)
      allow(File).to receive(:read).with("#{tmpdir}/source/.bt.yml").and_return(build_config_fixture)
      allow(Rails.application.routes.url_helpers).to receive(:build_repos_url).and_return("http://example.com/")
      allow_any_instance_of(GitApi).to receive(:set_status)
      ENV['GIT_SSH_COMMAND'] = nil
      build.save
    end

    after do
      if File.exists? tmpdir
        FileUtils.remove_entry tmpdir
      end
      ENV['GIT_SSH_COMMAND'] = nil
    end

    it "sets the status to error if there was an exception" do
      allow(build_job).to receive(:write_private_key).and_raise(StandardError)
      expect do
        build_job.perform
      end.to_not raise_error
      expect(build.status).to eq('error')
    end

    it "sets the build status multiple times during run" do
      expect(build_job).to receive(:set_status).with(:pending).once
      expect(build_job).to receive(:set_status).with(:success).once
      # Unfortunately I'm not able to inspect the database field here
      # Also unfortunate that the call to GitApi isn't tested well here
      build_job.perform
    end

    it "doesn't fail the build if it can't set the status on github" do
      allow_any_instance_of(GitApi).to receive(:set_status).and_raise(Octokit::UnprocessableEntity)
      expect do
        build_job.perform
      end.to_not raise_error
    end

    it "sets the sha of the build if it's not already set" do
      build.sha = nil
      expect_any_instance_of(GitApi).to receive(:head_sha).with(repo.short_name, build.branch).and_return("a"*40)
      build_job.perform
      expect(build.sha).to eq("a"*40)
    end

    it "creates a temporary directory" do
      expect(Dir).to receive(:mktmpdir)
      build_job.perform
    end

    it "sets the private key" do
      build_job.perform
      private_key_path = "#{tmpdir}/private_key.pem"
      private_key = ""
      # This is due to some weird stubbing behavior preventing File.read
      # when it's already stubbed. Ideally we'd just call File.read.
      File.open(private_key_path) do |fh|
        private_key = fh.read
      end
      expect(SSHKey.new(private_key).fingerprint).to eq(repo.fingerprint)
      expect(File.stat(private_key_path).mode).to eq(0100600)
      expect(build_job.instance_variable_get('@git_ssh_cmd')).to eq("GIT_SSH_COMMAND='ssh -i #{private_key_path}'")
    end

    it "executes a git clone operation" do
      expected_git_clone_cmd = "git clone git@github.com:pcorliss/design_patterns.git --branch master --single-branch --depth 10 #{tmpdir}/source"
      expect(build_job).to receive(:system_cmd).with(expected_git_clone_cmd)
      build_job.perform
    end

    it "fails the build if the git clone operation fails" do
      expected_git_clone_cmd = "git clone git@github.com:pcorliss/design_patterns.git --branch master --single-branch --depth 10 #{tmpdir}/source"
      expect(build_job).to receive(:system_cmd).with(expected_git_clone_cmd).and_return(fail_process)
      build_job.perform
      expect(build.success?).to be_falsey
    end

    it "executes a git checkout to the specified SHA" do
      expected_git_co_cmd = "cd #{tmpdir}/source && git checkout ffcaf395a6bb110182d357cebb4b9b49e34b6394"
      expect(build_job).to receive(:system_cmd).with(expected_git_co_cmd)
      build_job.perform
    end

    it "fails the build if it can't checkout the sha" do
      expected_git_co_cmd = "cd #{tmpdir}/source && git checkout ffcaf395a6bb110182d357cebb4b9b49e34b6394"
      expect(build_job).to receive(:system_cmd).with(expected_git_co_cmd).and_return(fail_process)
      build_job.perform
      expect(build.success?).to be_falsey
    end

    it "writes the generated build config to a file" do
      build_job.perform
      script_path = "#{tmpdir}/bt.sh"
      expect(File.exists?(script_path)).to be_truthy
      expect(File.stat(script_path).mode).to eq(0100755)
    end

    it "generates a config from the subproject path config" do
      build.sub_project_path = "foo/bar/foo/.bt.yml"
      expect(File).to receive(:read).with("#{tmpdir}/source/foo/bar/foo/.bt.yml").and_return(build_config_fixture)
      build_job.perform
    end

    it "runs docker container" do
      expected_docker_cmd = "docker run --rm -i --privileged -v #{tmpdir}:/var/ci ubuntu:15.10 /var/ci/bt.sh"
      expect(build_job).to receive(:system_cmd).with(expected_docker_cmd)
      build_job.perform
    end

    it "uses the exit code of the docker container to set the repo status" do
      build_job.perform
      expect(build.success?).to be_truthy
    end

    it "uses the exit code of the docker container to set a failing repo status" do
      allow(build_job).to receive(:system_cmd).and_return(fail_process)
      build_job.perform
      expect(build.success?).to be_falsey
    end

    it "saves the build" do
      build_job.perform
      expect(build.new_record?).to be_falsey
    end

    context "docker compose configuration" do
      let(:build_config_fixture) { File.read('spec/fixtures/docker_compose_build_config.yml') }
      let(:expected_compose_yml_path) { "#{tmpdir}/source/docker-compose-ci.yml" }
      let(:modified_compose_yml_path) { "#{expected_compose_yml_path}.ci" }
      let(:app_compose_yml_fixture) { YAML.load_file(app_compose_yml_path) }

      before do
        allow(YAML).to receive(:load_file).with(expected_compose_yml_path).and_return(app_compose_yml_fixture)
        expect(build_job).to receive(:system_cmd).with(/git clone /) do
          Dir.mkdir "#{tmpdir}/source"
          mock_process
        end
      end

      shared_examples "docker compose" do
        it "creates a compose_ci.yml to execute the CI instructions" do
          build_job.perform

          expect(File.exists?(modified_compose_yml_path)).to be_truthy

          allow(YAML).to receive(:load_file).with(modified_compose_yml_path).and_call_original
          compose_yaml = YAML.load_file(modified_compose_yml_path)

          expect(compose_yaml["web"]["volumes"]).to include("#{tmpdir}:/var/ci")
          expect(compose_yaml["web"]["command"]).to eq "/var/ci/bt.sh"
        end

        it "runs docker containers" do
          expected_docker_cmd = "docker-compose -f #{modified_compose_yml_path} run --rm web"
          expect(build_job).to receive(:system_cmd).with(expected_docker_cmd)
          build_job.perform
        end
      end

      context "volumes specified" do
        let(:app_compose_yml_path) { "spec/fixtures/docker_compose_app_config.yml" }

        it_behaves_like "docker compose"
      end

      context "no volumes/command specified" do
        let(:app_compose_yml_path) { "spec/fixtures/docker_compose_app_config_no_volumes.yml" }

        it_behaves_like "docker compose"
      end
    end

    context "dependent builds" do
      before do
        allow(Delayed::Job).to receive(:enqueue)
      end

      # This can happen if a dependent build isn't yet in the system
      context "without a repo" do
        let(:build_config_fixture) { File.read('spec/fixtures/parallel_build_config.yml') }

        it "ignores the build if it doesn't have a repo" do
          expect do
            build_job.perform
          end.to change{Build.count}.by(1)
          expect(Build.all.map(&:repo).any?(&:nil?)).to be_falsey
        end
      end

      context "with a repo" do
        let(:repo) { FactoryGirl.create(:private_key_repo, organization: 'foo', name: 'bar') }

        before do
          repo
        end

        context "parallel builds" do
          let(:build_config_fixture) { File.read('spec/fixtures/parallel_build_config.yml') }

          it "creates build objects" do
            expect do
              build_job.perform
            end.to change{Build.count}.by(2)
          end

          it "enqueus build objects" do
            expect(Delayed::Job).to receive(:enqueue).twice
            build_job.perform
          end
        end

        context "after success builds" do
          let(:build_config_fixture) { File.read('spec/fixtures/after_success_build_config.yml') }
          it "creates build objects" do
            expect do
              build_job.perform
            end.to change{Build.count}.by(2)
          end

          it "enqueus build objects" do
            expect(Delayed::Job).to receive(:enqueue).twice
            build_job.perform
          end

          it "does not enqueue build objects if the build fails" do
            allow(build_job).to receive(:run_docker_container).and_return(fail_process)

            expect do
              build_job.perform
            end.to_not change{Build.count}
          end

        end
      end
    end
  end
end
