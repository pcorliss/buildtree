class BuildConfig

  DEFAULT_DOCKER_IMAGE = 'ubuntu:14.04'

  def initialize(project = {})
    @config = YAML.load(project[:config] || '') || {}
    @sha = project[:sha]
    @branch = project[:branch]
    @repo = project[:repo]
    @dir = '/var/ci/source'
  end

  def docker_image
    @config['docker_image'] || DEFAULT_DOCKER_IMAGE
  end

  def header
    <<-EOS
#!/bin/bash

set -o nounset
set -o errexit

cd #{@dir}
EOS
  end

  def environment_variables
    env_config.map do |key, val|
      "export #{key}=\"#{val}\"\n"
    end.join
  end

  def packages
    return "" unless @config['packages']
    package_list = @config['packages'].join(" ")
<<-EOS
if type apt-get 2>/dev/null; then
  apt-get update -y
  apt-get install -y #{package_list}
else
  yum install #{package_list}
fi
EOS
  end

  def package_setup
    join_cmds('package_setup')
  end

  def service_provisioning
    return "" unless @config['services']
    @config['services'].map do |service|
<<-EOS
if [ -f "/etc/init.d/#{service}" ]; then
  /etc/init.d/#{service} start
else
  systemctl start #{service}
fi
EOS
    end.join("\n")
  end

  def setup_cmds
    join_cmds('setup')
  end

  def dependencies
    join_cmds('dependencies')
  end

  def test
    join_cmds('test')
  end

  def deployments
    return "" unless @config['deploy']
    @config['deploy'].map do |name, deploy_config|
      deploy = %Q[if [ "#{deploy_config['branch']}" == "$BRANCH" ]; then\n]
      deploy_config['cmds'].each do |cmd|
        deploy << ("  " + cmd + "\n")
      end
      deploy << "fi\n"
    end.join("\n")
  end

  def write(path)
    File.open(path, 'w') do |fh|
      fh.puts self.header
      fh.puts
      fh.puts self.environment_variables
      fh.puts
      fh.puts self.packages
      fh.puts
      fh.puts self.package_setup
      fh.puts
      fh.puts self.service_provisioning
      fh.puts
      fh.puts self.setup_cmds
      fh.puts
      fh.puts self.dependencies
      fh.puts
      fh.puts self.test
      fh.puts
      fh.puts self.deployments
      fh.chmod(0755)
    end
  end

  def child_builds
    parallel_build_configs = @config["build_in_parallel"] || []
    dependent_build_configs = @config["build_on_success"] || []

    children = []

    parallel_build_configs.each do |build|
      build = build_from_config(build)
      build.parallel = true
      children << build
    end

    dependent_build_configs.each do |build|
      build = build_from_config(build)
      build.parallel = false
      children << build
    end

    children
  end

  private

  def build_from_config(config)
    build = Hashie::Mash.new
    build.repo = repo_from_config(config)
    build.env = env_from_config(config)
    build.sub_project_path = config['sub_project']
    build
  end

  def repo_from_config(config)
    repo = Hashie::Mash.new
    if config['sub_project']
      repo.organization, repo.name = @repo.split('/')
      repo.service = 'github'
    else
      repo.service = config['service']
      repo.organization = config['organization']
      repo.name = config['name']
    end
    repo
  end

  def env_from_config(config)
    env = Hashie::Mash.new(config['env'])
    env['PARENT_SHA'] = @sha
    env['PARENT_BRANCH'] = @branch
    env
  end

  def env_config
    return @env_config if @env_config
    @env_config = @config['env'] || {}
    @env_config["SHA"] = @sha if @sha
    @env_config["BRANCH"] = @branch if @branch
    @env_config["REPO"] = @repo if @repo
    @env_config["DIR"] = @dir

    @env_config
  end

  def join_cmds(key)
    return "" unless @config[key]
    @config[key].join("\n")
  end
end
