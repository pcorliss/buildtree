class ReposController < ApplicationController
  before_filter :require_session, only: [:new, :create, :show]
  before_filter :load_repo, only: [:show, :webhook]
  skip_before_filter :verify_authenticity_token, :only => [:webhook]

  def new
    @repos = user_repos
  end

  def create
    repo = Repo.find_or_initialize_by_api(Hashie::Mash.new(params[:repo]))

    unless authorized_for_repo?(repo)
      return redirect_with_error(new_repo_path, "You do not have rights to create this repo")
    end

    git_api = GitApi.new(current_user)
    set_deploy_key!(git_api, repo)
    set_webhook!(git_api, repo)

    repo.save
    redirect_to repo_path(repo)
  rescue Octokit::NotFound
    redirect_with_error(new_repo_path, "You do not have rights to create this repo")
  end

  def show
    require_repo_permissions
  end

  def webhook
    if 'ping' == request.headers['X-GitHub-Event']
      return render :json => {event: 'pong'}
    end

    webhook_body = JSON.parse(request.body.read)
    sha = webhook_sha(webhook_body)
    branch = webhook_branch(webhook_body)

    return render_422 unless sha.present? && branch.present?
    unless @repo.builds.exists?(branch: branch, sha: sha)
      @repo.builds.create(branch: branch, sha: sha)
    end
    render :json => {}
  rescue JSON::ParserError
    render_422
  end

  private

  def webhook_sha(webhook_body)
    if webhook_body['head_commit']
      webhook_body['head_commit']['id']
    else
      webhook_body['pull_request']['head']['sha']
    end
  rescue NoMethodError
    nil
  end

  def webhook_branch(webhook_body)
    if webhook_body['ref']
      webhook_body['ref'][/^refs.heads.(.*)/]
      $1
    else
      webhook_body['pull_request']['head']['ref']
    end
  rescue NoMethodError
    nil
  end

  def set_deploy_key!(git_api, repo)
    if !repo.private_key || !git_api.deploy_key_exists?(repo.organization, repo.name, repo.fingerprint)
      private_key = git_api.add_new_deploy_key(repo.organization, repo.name)
      repo.private_key = private_key
    end
  end

  def set_webhook!(git_api, repo)
    webhook_url = webhook_repos_url(repo.slice(:service, :organization, :name).symbolize_keys)
    unless git_api.webhook_exists?(repo.organization, repo.name, webhook_url)
      git_api.add_new_webhook(repo.organization, repo.name, webhook_url)
    end
  end
end
