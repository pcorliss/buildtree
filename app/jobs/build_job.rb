require 'open3'

class BuildJob
  def initialize(build)
    @build = build
    @repo = build.repo
  end

  def perform
    tmpdir do |dir|
      write_private_key(dir)
      git_clone(dir)
      run_docker_container(dir)
    end
  end

  private
  def tmpdir
    Dir.mktmpdir("build_job") { |dir| yield(dir) }
  end

  def write_private_key(dir)
    File.open("#{dir}/private_key.pem", 'w') do |fh|
      fh.chmod(0600)
      fh.write SSHKey.new(@repo.private_key, passphrase: ENV['SSH_PASSPHRASE']).private_key
      ENV['GIT_SSH_COMMAND'] = "ssh -i #{fh.path}"
    end
  end

  def git_clone(dir)
    system_cmd("git clone #{@repo.git_url} --branch #{@build.branch} --single-branch --depth 10 #{dir}/source")
  end

  def run_docker_container(dir)
    system_cmd("docker run -t -i -v #{dir}:/var/ci ubuntu:14.04 /var/ci/source/ci.sh")
  end

  def system_cmd(cmd)
    exit_code = nil
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      stdout.gets(nil)
      stdout.close
      stderr.gets(nil)
      stderr.close
      exit_code = wait_thr.value
    end
    exit_code
  end
end
