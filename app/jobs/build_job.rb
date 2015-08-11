require 'open3'
require 'tempfile'

class BuildJob
  STATUS_TO_DESCRIPTION = {
    pending: "Build is in progress",
    failure: "Build failed",
    error: "Build has errored out",
    success: "Build has succeeded",
  }

  def initialize(build)
    @build = build
    @repo = build.repo
  end

  def perform
    set_sha if @build.sha.nil?
    set_status(:pending)
    tmpdir do |dir|
      write_private_key(dir)
      return short_circuit! if short_circuit?(git_clone(dir))
      return short_circuit! if short_circuit?(git_checkout(dir))
      #build_config(dir).start_parallel_builds
      build_config(dir).write("#{dir}/bt.sh")
      return short_circuit! if short_circuit?(run_docker_container(dir))
      set_status(:success)
      #build_config(dir).start_dependent_builds
    end
  end

  private

  def set_sha
    GitApi.with_authorized_users(authorized_users) do |api|
      sha = api.head_sha(@repo.short_name, @build.branch)
      @build.sha = sha
      @build.save
    end
  end

  def set_status(status)
    @build.status = status
    @build.save
    @auth_user = GitApi.with_authorized_users(authorized_users) do |api|
      api.set_status(
        repo: @repo.short_name,
        sha: @build.sha,
        status: status,
        description: STATUS_TO_DESCRIPTION[status],
        context: "BuildTree",
        target_url: build_url,
      )
    end
  end

  def build_url
    Rails.application.routes.url_helpers.build_repos_url(@repo.to_params.symbolize_keys.merge(id: @build.id, host: ENV['DEFAULT_HOST']))
  end

  def authorized_users
    return [@auth_user] if @auth_user
    @repo.users.shuffle
  end

  def short_circuit?(process)
    process.exitstatus > 0
  end

  def short_circuit!
    set_status(:failure)
  end

  def tmpdir
    Dir.mktmpdir("build_job", ENV['TMPDIR']) { |dir| yield(dir) }
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

  def git_checkout(dir)
    system_cmd("cd #{dir}/source && git checkout #{@build.sha}")
  end

  def build_config(dir)
    @build_config ||= BuildConfig.new(
      config: File.read("#{dir}/source/.bt.yml"),
      repo: @repo.short_name,
      branch: @build.branch,
      sha: @build.sha,
      dir: "#{dir}/source",
    )
  end

  def run_docker_container(dir)
    system_cmd("docker run --rm -i --privileged -v #{dir}:/var/ci #{build_config(dir).docker_image} /var/ci/bt.sh")
  end

  # IO Select usage cargo culted from https://gist.github.com/chrisn/7450808
  def system_cmd(cmd)
    exit_val = nil
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      stdin.close

      block_size = 1
      io_buffers = {stdout: '', stderr: ''}
      output_buffer = []
      outputs = {stdout => :stdout, stderr => :stderr}

      begin
        until outputs.keys.all?(&:eof) do
          ready = IO.select(outputs.keys)
          if ready
            readable = ready[0]
            readable.each do |f|
              file_type = outputs[f]
              begin
                data = f.read_nonblock(block_size)

                io_buffers[file_type] << data
                if data == "\n"
                  payload = {file_type => io_buffers[file_type]}
                  puts payload.inspect
                  output_buffer << payload

                  io_buffers[file_type] = ""
                end
              rescue EOFError
              end
            end
          end
        end
      rescue IOError
      end

      exit_val = wait_thr.value
      @build.build_logs.create(
        text: output_buffer.to_json,
        cmd: cmd,
        exit_code: exit_val,
      )
    end

    exit_val
  end
end
