fqdn = 'example.com'

fqdn = `hostname -f` if `which hostname`
Rails.application.routes.default_url_options[:host] = ENV['HOST'] || fqdn
