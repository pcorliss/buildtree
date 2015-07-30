require 'spec_helper'
require './lib/build_config'

describe BuildConfig do
  let(:build_config_fixture) { File.read('spec/fixtures/build_config.yml') }
  let(:project_info) {{
    dir: '/tmp',
    config: build_config_fixture,
    repo: 'foo/bar',
    sha: 'a'*40,
    branch: 'master',
  }}
  let(:build_config) { BuildConfig.new(project_info) }
  let(:empty_build_config) { BuildConfig.new }

  describe "#docker_image" do
    it "returns docker image specified" do
      expect(build_config.docker_image).to eq('ubuntu:15.10')
    end

    it "uses the default docker image if not specified" do
      expect(empty_build_config.docker_image).to eq('ubuntu:14.04')
    end
  end

  describe "#environment_variables" do
    it "returns shell code to be executed" do
      expect(build_config.environment_variables).to include(%Q[export FOO="foo"\n])
      expect(build_config.environment_variables).to include(%Q[export BAR="bar"\n])
    end

    it "sets the project repo" do
      expect(build_config.environment_variables).to include(%Q[export REPO="foo/bar"\n])
    end

    it "sets the project dir" do
      expect(build_config.environment_variables).to include(%Q[export DIR="/tmp"\n])
    end

    it "sets the sha" do
      sha = "a"*40
      expect(build_config.environment_variables).to include(%Q[export SHA="#{sha}"\n])
    end

    it "sets the branch" do
      expect(build_config.environment_variables).to include(%Q[export BRANCH="master"\n])
    end

    it "returns an empty string with a blank config" do
      expect(empty_build_config.environment_variables).to be_empty
    end
  end

  # Need to figure this out
  describe "#secrets"

  describe "#packages" do
    it "installs packages via apt or yum" do
      expected_install = <<-EOS
if type apt-get 2>/dev/null; then
  apt-get update -y
  apt-get install -y curl wget
else
  yum install curl wget
fi
      EOS
      expect(build_config.packages).to include(expected_install)
    end

    it "returns an empty string with a blank config" do
      expect(empty_build_config.packages).to be_empty
    end
  end

  describe "#package_setup" do
    it "runs arbitrary commands" do
      expect(build_config.package_setup).to include("some_cmd foo bar buzz")
      expect(build_config.package_setup).to include("some_other_cmd")
    end

    it "returns an empty string with a blank config" do
      expect(empty_build_config.package_setup).to be_empty
    end
  end

  describe "#service_provisioning" do
    it "starts services via init script or systemd" do
      expected_init = <<-EOS
if [ -f "/etc/init.d/cassandra" ]; then
  /etc/init.d/cassandra start
else
  systemctl start cassandra
fi
EOS
      expect(build_config.service_provisioning).to include(expected_init)
    end

    it "returns an empty string with a blank config" do
      expect(empty_build_config.service_provisioning).to be_empty
    end
  end

  describe "#setup" do
    it "runs arbitrary commands" do
      expect(build_config.setup_cmds).to include("some_cmd foo bar buzz")
      expect(build_config.setup_cmds).to include("some_other_cmd")
    end

    it "returns an empty string with a blank config" do
      expect(empty_build_config.setup_cmds).to be_empty
    end
  end

  # isn't a must have, but would be nice to have a way of handling this
  # other than custom images
  describe "#language_selection"

  describe "#dependencies" do
    it "runs arbitrary commands" do
      expect(build_config.dependencies).to include("bundle install")
      expect(build_config.dependencies).to include("mvn clean dependencies")
    end

    it "returns an empty string with a blank config" do
      expect(empty_build_config.dependencies).to be_empty
    end
  end

  describe "#test" do
    it "runs arbitrary commands" do
      expect(build_config.test).to include("rake")
      expect(build_config.test).to include("mvn test")
    end

    it "returns an empty string with a blank config" do
      expect(empty_build_config.test).to be_empty
    end
  end

  describe "#deployments" do
    it "conditionally runs a deploy based on the branch" do
      expected = <<-EOS
if [ "master" == "$BRANCH" ]; then
  asdf
  bar
fi

if [ "release" == "$BRANCH" ]; then
  fubar
fi
EOS
      expect(build_config.deployments).to include(expected)
    end

    it "returns an empty string with a blank config" do
      expect(empty_build_config.deployments).to be_empty
    end
  end

  describe "#notifications"

  describe "#header" do
    it "returns a header" do
      header = <<-EOS
#!/bin/bash

set -o nounset
set -o errexit

cd /tmp
EOS
      expect(build_config.header).to eq(header)
    end
  end

  describe "#write" do
    let(:expected_build_script) { File.read('spec/fixtures/bt.sh') }

    it "writes a build script from components" do
      file = StringIO.new
      expect(File).to receive(:open).with("filename", "w").and_yield(file)
      build_config.write("filename")
      file.rewind
      expect(file.read).to eq(expected_build_script)
    end
  end
end
