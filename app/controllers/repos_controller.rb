class ReposController < ApplicationController
  before_filter :require_session

  def new
    @user_repos = user_repos
    render :json => @user_repos
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
    load_repo
    require_repo_permissions
    render :json => {}
  end

  def webhook
    render :json => {}
  end

  private

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
