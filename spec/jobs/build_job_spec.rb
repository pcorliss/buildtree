require 'rails_helper'

describe BuildJob do
  let(:repo) { FactoryGirl.build(:private_key_repo) }
  let(:build) { FactoryGirl.build(:build, repo: repo) }
  let(:build_job) { BuildJob.new(build) }
  let(:tmpdir) { Dir.mktmpdir('build_job_spec') }

  describe "#perform" do
    before do
      allow(Dir).to receive(:mktmpdir).and_yield(tmpdir)
      allow(build_job).to receive(:system_cmd).and_return(0)
      ENV['GIT_SSH_COMMAND'] = nil
    end

    after do
      if File.exists? tmpdir
        FileUtils.remove_entry tmpdir
      end
      ENV['GIT_SSH_COMMAND'] = nil
    end

    it "creates a temporary directory" do
      expect(Dir).to receive(:mktmpdir)
      build_job.perform
    end

    it "sets the private key" do
      build_job.perform
      private_key_path = "#{tmpdir}/private_key.pem"
      private_key = File.read(private_key_path)
      expect(SSHKey.new(private_key).fingerprint).to eq(repo.fingerprint)
      expect(File.stat(private_key_path).mode).to eq(0100600)
      expect(ENV['GIT_SSH_COMMAND']).to eq("ssh -i #{private_key_path}")
    end

    it "executes a git clone operation" do
      expected_git_clone_cmd = "git clone git@github.com:pcorliss/design_patterns.git --branch master --single-branch --depth 10 #{tmpdir}/source"
      expect(build_job).to receive(:system_cmd).with(expected_git_clone_cmd)
      build_job.perform
    end

    it "runs docker container" do
      expected_docker_cmd = "docker run -i -v #{tmpdir}:/var/ci ubuntu:14.04 /var/ci/source/ci.sh"
      expect(build_job).to receive(:system_cmd).with(expected_docker_cmd)
      build_job.perform
    end
  end
end
