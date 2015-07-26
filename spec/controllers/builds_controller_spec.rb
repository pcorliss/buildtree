require 'rails_helper'

describe BuildsController do
  context "routing" do
    it "routes to #show" do
      expect(get: "/builds/1").to route_to(
        :controller => "builds",
        :action => "show",
        :id => "1",
      )
    end

    it "routes to vanity #show" do
      expect(get: "/repos/github/foo/bar/1").to route_to(
        :controller => "builds",
        :action => "show",
        :service => "github",
        :organization => "foo",
        :name => "bar",
        :id => "1",
      )
    end
  end

  describe "#show" do
    let(:build) { FactoryGirl.create(:build) }
    let(:repo) { build.repo }
    let(:repo_api_params) {{ service: repo.service, owner: repo.organization, name: repo.name }}
    let(:build_params) { repo.slice(:service, :organization, :name).merge(build.slice(:id)) }
    let(:user) { FactoryGirl.create(:user) }

    context "signed out" do
      it "redirects the user to sign in" do
        get :show, id: build
        expect(flash[:error]).to eq(["Please log in"])
        expect(response).to redirect_to(signin_auth_path)
      end
    end

    context "signed in" do
      before do
        session[:user_id] = user.id
        repos = [Hashie::Mash.new(repo_api_params)]
        allow_any_instance_of(GitApi).to receive(:repos).and_return(repos)
      end

      context "unauthorized" do
        it "returns a 404 if the user isn't authorized to view the repo" do
          expect_any_instance_of(GitApi).to receive(:repos).and_return([])
          expect do
            get :show, id: build
          end.to raise_error(ActionController::RoutingError)
        end
      end

      context "authorized" do
        it "returns a 200 response" do
          get :show, id: build
          expect(response).to have_http_status(:ok)
        end

        it "assigns build when accessed via id" do
          get :show, id: build
          expect(assigns(:build)).to eq(build)
        end
      end
    end
  end
end
