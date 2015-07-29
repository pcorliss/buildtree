require 'open3'
require 'tempfile'

class BuildJob
  def initialize(build)
    @build = build
    @repo = build.repo
  end

  def perform
    tmpdir do |dir|
      write_private_key(dir)
      git_clone(dir)
      process = run_docker_container(dir)
      @build.success = (process.exitstatus == 0)
      #`cp -pr #{dir} tmp/`
    end
  end

  private
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

  def run_docker_container(dir)
    system_cmd("docker run -i -v #{dir}:/var/ci ubuntu:14.04 /var/ci/source/ci.sh")
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