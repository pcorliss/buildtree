class BuildsController < ApplicationController
  before_filter :require_session, only: [:show]
  before_filter :load_build, only: [:show]
  before_filter :require_repo_permissions, only: [:show]

  def show
  end
end
