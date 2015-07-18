class User < ActiveRecord::Base
  validates_presence_of :provider, :uid

  def self.find_or_create_from_auth_hash(auth_hash)
    provider = auth_hash['provider']
    uid = auth_hash['uid']
    user = User.find_or_create_by(provider: provider, uid: uid)
    user.update_attributes(auth_hash_params(auth_hash))
    user
  end

  def slug
    "#{provider}_#{uid}"
  end

  private

  def self.auth_hash_params(auth_hash)
    info = auth_hash['info'] || {}
    credentials = auth_hash['credentials'] || {}
    {
      name: info['name'],
      email: info['email'],
      avatar: info['avatar'] || info['image'],
      token: credentials['token'],
      secret: credentials['secret'],
    }
  end
end
