require 'octokit'
require 'hashie'
require 'sshkey'

class GitApi
  attr_reader :source, :service

  def initialize(user)
    @service = user.provider.to_sym
    @source = case service
      when :github
        Octokit::Client.new(:access_token => user.token)
    end
  end

  def repos
    case service
      when :github
        github_repos
    end
  end

  def add_new_deploy_key(owner, name)
    raise StandardError, "ENV['SSH_KEY_SIZE'] may not be blank" if ENV['SSH_KEY_SIZE'].to_s.empty?
    raise StandardError, "ENV['SSH_PASSPHRASE'] may not be blank" if ENV['SSH_PASSPHRASE'].to_s.empty?

    key = SSHKey.generate(
      :bits => ENV['SSH_KEY_SIZE'].to_i,
      :comment => "GitSentry.com - Generated for #{service}/#{owner}/#{name} - #{Time.now}",
      :passphrase => ENV['SSH_PASSPHRASE']
    )

    case service
      when :github
        github_add_key(owner, name, key)
    end

    key.encrypted_private_key
  end

  def deploy_key_exists?(owner, name, fingerprint)
    deploy_keys = case service
      when :github
        github_deploy_keys(owner, name)
    end

    deploy_keys.any? do |key_entry|
      SSHKey.fingerprint(key_entry[:key]) == fingerprint
    end
  end

  private

  def github_deploy_keys(owner, name)
    source.deploy_keys "#{owner}/#{name}"
  end

  def github_add_key(owner, name, key)
    source.add_deploy_key("#{owner}/#{name}", 'GitSentry', key.ssh_public_key)
  end

  def bitbucket_add_key(owner, name, key)
    source.repos.keys.create owner, name, :label => 'gitsentry', :key => key.ssh_public_key
  end

  def github_repos
    source.repos.map do |repo|
      Hashie::Mash.new(
        service: 'github',
        owner: repo.owner.login,
        name: repo.name,
        private: repo.private
      )
    end
  end

  def bitbucket_repos
    source.repos.list.map do |repo|
      Hashie::Mash.new(
        service: 'bitbucket',
        owner: repo.owner,
        name: repo.name,
        private: repo.is_private
      )
    end
  end
end
