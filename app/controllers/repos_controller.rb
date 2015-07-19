class ReposController < ApplicationController
  before_filter :require_session

  def new
    @user_repos = user_repos
    render :json => @user_repos
  end

  def create
    repo = Repo.find_or_initialize_by_api(Hashie::Mash.new(params[:repo]))
    if authorized_for_repo?(repo)
      git_api = GitApi.new(current_user)

      if repo.private_key
        fingerprint = SSHKey.new(repo.private_key, passphrase: ENV['SSH_PASSPHRASE'])
        unless git_api.deploy_key_exists?(repo.organization, repo.name, fingerprint)
          #recreate
        end
      else
        private_key = git_api.add_new_deploy_key(repo.organization, repo.name)
        repo.private_key = private_key
      end

      repo.save
      render :json => {}
    else
      flash[:error] ||= []
      flash[:error] << "You do not have rights to create this repo"
      redirect_to new_repo_path
    end
  end
end
