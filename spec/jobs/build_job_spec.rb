require 'rails_helper'

describe BuildJob do
  let(:repo) { FactoryGirl.build(:private_key_repo, users: [user]) }
  let(:build) { FactoryGirl.build(:build, repo: repo, status: 0, build_status: 0) }
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

    it "sets the build status multiple times during run" do
      expect(build_job).to receive(:set_status).with(:pending).once
      expect(build_job).to receive(:set_status).with(:success).once
      # Unfortunately I'm not able to inspect the database field here
      # Also unfortunate that the call to GitApi isn't tested well here
      build_job.perform
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
      expect(ENV['GIT_SSH_COMMAND']).to eq("ssh -i #{private_key_path}")
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

    context "parallel builds" do
      let(:build_config_fixture) { File.read('spec/fixtures/parallel_build_config.yml') }

      before do
        allow(Delayed::Job).to receive(:enqueue)
      end

      it "creates build objects" do
        expect do
          build_job.perform
        end.to change{Build.count}.by(2)
      end

      it "enqueus build objects" do
        expect(Delayed::Job).to receive(:enqueue).twice
        build_job.perform
      end

      it "sets success only after all parallel jobs are complete"
    end

    context "after success builds" do
      let(:build_config_fixture) { File.read('spec/fixtures/after_success_build_config.yml') }

      before do
        allow(Delayed::Job).to receive(:enqueue)
      end

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

      it "sets success independent of after success builds"
    end
  end
end
