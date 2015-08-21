if host = ENV['GHE_HOST']
  Octokit.configure do |c|
    c.api_endpoint = "https://#{host}/api/v3"
    c.web_endpoint = "https://#{host}"
  end
end
