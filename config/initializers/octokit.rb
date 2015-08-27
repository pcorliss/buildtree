Octokit.configure do |c|
  if host = ENV['GHE_HOST']
    c.api_endpoint = "https://#{host}/api/v3"
    c.web_endpoint = "https://#{host}"
    # Uncomment to use the Organization Permissions API Preview
    # https://developer.github.com/enterprise/2.2/changes/2015-01-07-prepare-for-organization-permissions-changes/
    # c.default_media_type = "application/vnd.github.moondragon+json"
  end
  c.auto_paginate = true
end
