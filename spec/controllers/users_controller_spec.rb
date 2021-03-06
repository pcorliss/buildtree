require 'rails_helper'

describe UsersController do
  context "routing" do
    it "routes to #show" do
      expect(get: "/users/1").to route_to(
        :controller => "users",
        :action => "show",
        :id => "1",
      )
    end

    it "routes to #show" do
      expect(post: "/users/sync").to route_to(
        :controller => "users",
        :action => "sync",
      )
    end
  end

  describe "#show" do
    let(:user) { FactoryGirl.create(:user) }
    let(:repo_a) { FactoryGirl.create(:repo, name: "a") }
    let(:repo_b) { FactoryGirl.create(:repo, name: "b") }
    let(:build_a) { FactoryGirl.create(:build, repo: repo_a) }
    let(:build_b) { FactoryGirl.create(:build, repo: repo_b) }

    context "signed out" do
      it "redirects the user to sign in" do
        get :show, id: user
        expect(flash[:error]).to eq(["Please log in"])
        expect(response).to redirect_to(signin_auth_path)
      end
    end

    context "signed in" do
      before do
        session[:user_id] = user.id
      end

      # We explicitly allow all logged in users to view other users dashboards
      it "returns a 200 response" do
        get :show, id: user
        expect(response).to have_http_status(:ok)
      end

      it "assigns user when accessed via id" do
        get :show, id: user
        expect(assigns(:user)).to eq(user)
        expect(assigns(:display_user)).to eq(user)
      end

      it "assigns other_user when accessed via id" do
        other_user = FactoryGirl.create(:user)
        get :show, id: other_user
        expect(assigns(:user)).to eq(user)
        expect(assigns(:display_user)).to eq(other_user)
      end

      it "assigns builds" do
        expected_builds = [build_a, build_b].reverse # lazy loading
        user.repos = [repo_a, repo_b]
        get :show, id: user
        expect(assigns(:builds)).to eq(expected_builds)
      end
    end
  end

  describe "#sync" do
    let(:user) { FactoryGirl.create(:user) }
    let(:repo) { FactoryGirl.create(:repo, name: "a") }
    let(:api_repos) {[repo.to_api_params]}

    context "signed out" do
      it "redirects the user to sign in" do
        post :sync
        expect(flash[:error]).to eq(["Please log in"])
        expect(response).to redirect_to(signin_auth_path)
      end
    end

    context "signed in" do
      before do
        session[:user_id] = user.id
        allow_any_instance_of(GitApi).to receive(:repos).and_return(api_repos)
      end

      it "clears the cache on the user_repos for that user" do
        Rails.cache.write("user_repos_#{user.slug}", [])
        post :sync
        updated_cache = Rails.cache.fetch("user_repos_#{user.slug}")
        expect(updated_cache).to eq(api_repos)
      end

      it "redirects to the new repo page" do
        post :sync
        expect(response).to redirect_to(new_repo_path)
      end
    end
  end
end
