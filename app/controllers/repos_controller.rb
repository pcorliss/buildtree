class ReposController < ApplicationController
  before_filter :require_session, only: [:new, :create, :show, :follow, :unfollow, :build]
  before_filter :load_repo, only: [:show, :webhook, :follow, :unfollow, :build]
  before_filter :require_repo_permissions, only: [:show, :follow, :unfollow, :build]
  skip_before_filter :verify_authenticity_token, :only => [:webhook]

  def new
    @repos = user_repos.map do |repo|
      Repo.find_or_initialize_by_api(Hashie::Mash.new(repo))
    end
    @followed_repos = Set.new(current_user.repos) & Set.new(@repos)
  end

  def create
    repo = Repo.find_or_initialize_by(repo_params)

    unless authorized_for_repo?(repo)
      return redirect_with_error(new_repo_path, "You do not have rights to create this repo")
    end

    git_api = GitApi.new(current_user)
    set_deploy_key!(git_api, repo)
    set_webhook!(git_api, repo)

    repo.save
    current_user.repos << repo
    redirect_to repo_path(repo)
  rescue Octokit::NotFound
    redirect_with_error(new_repo_path, "You do not have rights to create this repo")
  end

  def show
    @builds = @repo.builds.order('id desc')
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
      build = @repo.builds.create(branch: branch, sha: sha)
      build.enqueue!
    end
    render :json => {}
  rescue JSON::ParserError
    render_422
  end

  def follow
    current_user.repos << @repo
    redirect_to new_repo_path
  end

  def unfollow
    current_user.repos.delete(@repo)
    redirect_to new_repo_path
  end

  def build
    git_api = GitApi.new(current_user)
    branch = git_api.default_branch(@repo.short_name)
    sha = git_api.head_sha(@repo.short_name, branch)
    build = @repo.builds.create(branch: branch, sha: sha)
    build.enqueue!
    redirect_to build_repos_path(@repo.to_params.merge(id: build).symbolize_keys)
  rescue Octokit::Conflict
    redirect_with_error(repo_path(@repo), "Repo is empty")
  end

  private

  def repo_params
    params.require(:repo).permit(:service, :organization, :name)
  end

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
