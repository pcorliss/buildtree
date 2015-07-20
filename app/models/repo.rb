class Repo < ActiveRecord::Base
  has_many :builds

  validates_presence_of :service, :organization, :name

  validates :service, inclusion: [ 'github' ]

  validates_uniqueness_of :name, scope: [:service, :organization]

  def external_url(*args)
    if service == 'github'
      github_external_url(*args)
    end
  end

  def git_url(*args)
    if service == 'github'
      github_git_url(*args)
    end
  end

  def short_name
    "#{organization}/#{name}"
  end

  def self.find_or_initialize_by_api(api_resp)
    repo = find_or_initialize_by(parsed_resp(api_resp))
    repo
  end

  # TODO Untested and duplicated code
  def self.initialize_by_api(api_resp)
    repo = new(parsed_resp(api_resp))
    repo
  end

  def ==(other)
    self.service == other.service &&
    self.organization == other.organization &&
    self.name == other.name
  end

  def fingerprint
    if self.private_key
      SSHKey.new(self.private_key, passphrase: ENV['SSH_PASSPHRASE']).fingerprint
    end
  end

  private

  def self.parsed_resp(api_resp)
    {
      service: api_resp.service,
      organization: api_resp.owner,
      name: api_resp.name,
    }
  end

  def github_external_url(sha = nil, file = nil, line = nil)
    external = "https://github.com/#{organization}/#{name}"
    if file.present?
      external << "/blob/#{sha}"
      external << "/#{file}"
      external << "#L#{line}" if line.present?
    else
      external << "/tree/#{sha}" if sha.present?
    end
    external
  end

  def github_git_url
    "git@github.com:#{self.organization}/#{self.name}.git"
  end
end
