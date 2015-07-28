require 'rails_helper'

describe ReposController do
  context "routing" do
    it "routes to #new" do
      expect(get: "/repos/new").to route_to("repos#new")
    end

    it "routes to #create" do
      expect(post: "/repos").to route_to("repos#create")
    end

    it "routes to #show" do
      expect(get: "/repos/1").to route_to(
        :controller => "repos",
        :action => "show",
        :id => "1",
      )
    end

    it "routes to vanity #show" do
      expect(get: "/repos/github/foo/bar").to route_to(
        :controller => "repos",
        :action => "show",
        :service => "github",
        :organization => "foo",
        :name => "bar",
      )
    end

    it "routes to #webhook" do
      expect(post: "/repos/github/foo/bar/webhook").to route_to(
        :controller => "repos",
        :action => "webhook",
        :service => "github",
        :organization => "foo",
        :name => "bar",
      )
    end

    it "routes to #follow" do
      expect(post: "/repos/github/foo/bar/follow").to route_to(
        :controller => "repos",
        :action => "follow",
        :service => "github",
        :organization => "foo",
        :name => "bar",
      )
    end

    it "routes to #unfollow" do
      expect(post: "/repos/github/foo/bar/unfollow").to route_to(
        :controller => "repos",
        :action => "unfollow",
        :service => "github",
        :organization => "foo",
        :name => "bar",
      )
    end

    it "handles names with periods in them" do
      expect(get: "/repos/github/foo/bar.foo").to route_to(
        :controller => "repos",
        :action => "show",
        :service => "github",
        :organization => "foo",
        :name => "bar.foo",
      )
    end
  end

  describe "#new" do
    context "signed out" do
      it "redirects the user to sign in" do
        get :new
        expect(flash[:error]).to eq(["Please log in"])
        expect(response).to redirect_to(signin_auth_path)
      end
    end

    context "signed in" do
      let(:user) { FactoryGirl.create(:user) }
      let(:repo) { FactoryGirl.create(:repo)}
      let(:private_repo) { FactoryGirl.create(:private_key_repo)}
      let(:repo_params) {{ service: repo.service, owner: repo.organization, name: repo.name }}
      let(:private_params) {{ service: private_repo.service, owner: private_repo.organization, name: private_repo.name }}

      before do
        session[:user_id] = user.id
      end

      it "Usees the API to grab the users repos" do
        repos = [repo_params]
        expect_any_instance_of(GitApi).to receive(:repos).and_return(repos)
        get :new
        expect(assigns(:repos)).to eq([repo])
      end

      it "assigns the intersection of repos a user already follows" do
        repos = [repo_params, private_params]
        allow_any_instance_of(GitApi).to receive(:repos).and_return(repos)
        user.repos << repo
        get :new
        expect(assigns(:followed_repos)).to eq(Set.new([repo]))
      end
    end
  end

  describe "#create" do
    context "signed out" do
      it "redirects the user to sign in" do
        post :create
        expect(flash[:error]).to eq(["Please log in"])
        expect(response).to redirect_to(signin_auth_path)
      end
    end

    context "signed in" do
      let(:user) { FactoryGirl.create(:user) }

      let(:repo) { FactoryGirl.build(:repo) }
      let(:private_repo) { FactoryGirl.build(:private_key_repo) }

      let(:valid_params) { repo.to_params }
      let(:private_params) { private_repo.to_params }
      let(:valid_api_params) { repo.to_api_params }
      let(:private_api_params) { private_repo.to_api_params }

      before do
        session[:user_id] = user.id
        repo_params = [valid_api_params, private_api_params]
        allow_any_instance_of(GitApi).to receive(:repos).and_return(repo_params)
        allow_any_instance_of(GitApi).to receive(:github_add_key)
        allow_any_instance_of(GitApi).to receive(:deploy_key_exists?).and_return(false)
        allow_any_instance_of(GitApi).to receive(:add_new_webhook)
        allow_any_instance_of(GitApi).to receive(:webhook_exists?).and_return(false)
      end

      it "creates a repo" do
        expect do
          post :create, repo: valid_params
        end.to change{Repo.count}.from(0).to(1)
      end

      it "doesn't create a repo that already exists" do
        repo.save
        expect do
          post :create, repo: valid_params
        end.to_not change{Repo.count}
      end

      it "doesn't create a repo if the user doesn't have rights to it" do
        allow_any_instance_of(GitApi).to receive(:repos).and_return([])
        expect do
          post :create, repo: valid_params
        end.to_not change{Repo.count}
        expect(flash[:error]).to eq(["You do not have rights to create this repo"])
        expect(response).to redirect_to(new_repo_path)
      end

      it "creates a webhook" do
        expect_any_instance_of(GitApi).to receive(:add_new_webhook)
        post :create, repo: valid_params
      end

      it "handles a non-admin error on hook creation and does not create the repo" do
        expect_any_instance_of(GitApi).to receive(:add_new_webhook).and_raise(Octokit::NotFound)
        post :create, repo: valid_params
        expect(flash[:error]).to eq(["You do not have rights to create this repo"])
        expect(response).to redirect_to(new_repo_path)
      end

      it "doesn't try to create a new webhook if one already exists" do
        expect_any_instance_of(GitApi).to receive(:webhook_exists?).and_return(true)
        expect_any_instance_of(GitApi).to_not receive(:add_new_webhook)
        post :create, repo: valid_params
      end

      it "creates a deploy key" do
        post :create, repo: valid_params
        expect(Repo.last.private_key).to_not be_nil
      end

      it "doesn't create a deploy key if one already exists" do
        repo = FactoryGirl.create(:private_key_repo)
        original_private_key = repo.private_key
        expect_any_instance_of(GitApi).to_not receive(:github_add_key)
        expect_any_instance_of(GitApi).to receive(:deploy_key_exists?).and_return(true)
        post :create, repo: private_params
        expect(repo.reload.private_key).to eq(original_private_key)
      end

      it "recreates the deploy key if it doesn't exist on the remote" do
        repo = FactoryGirl.create(:private_key_repo)
        original_private_key = repo.private_key
        expect_any_instance_of(GitApi).to receive(:github_add_key)
        expect_any_instance_of(GitApi).to receive(:deploy_key_exists?).and_return(false)
        post :create, repo: private_params
        expect(repo.reload.private_key).to_not be_nil
        expect(repo.private_key).to_not eq(original_private_key)
      end

      it "redirects to the repo show page" do
        post :create, repo: valid_params
        expect(response).to redirect_to(repo_path Repo.last)
      end

      it "follows the repo" do
        expect do
          post :create, repo: valid_params
        end.to change{UserRepo.count}.from(0).to(1)
      end
    end
  end

  describe "#show" do
    let(:repo) { FactoryGirl.create(:repo) }
    let(:repo_params) { repo.slice(:service, :organization, :name) }
    let(:repo_api_params) {{ service: repo.service, owner: repo.organization, name: repo.name }}
    let(:user) { FactoryGirl.create(:user) }

    context "signed out" do
      it "redirects the user to sign in" do
        get :show, id: repo
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
            get :show, repo_params
          end.to raise_error(ActionController::RoutingError)
        end
      end

      context "authorized" do
        it "returns a 200 response" do
          get :show, id: repo
          expect(response).to have_http_status(:ok)
        end

        it "assigns repo when accessed via id" do
          get :show, id: repo
          expect(assigns(:repo)).to eq(repo)
        end

        it "assigns repo when accessed via path" do
          get :show, repo_params
          expect(assigns(:repo)).to eq(repo)
        end
      end
    end
  end

  describe "#webhook", :type => :request do
    let(:repo) { FactoryGirl.create(:repo) }
    let(:push_event_body) { File.read('spec/fixtures/github_webhook_push.json') }
    let(:pr_event_body) { File.read('spec/fixtures/github_webhook_pr.json') }
    let(:ping_event_body) { File.read('spec/fixtures/github_webhook_ping.json') }
    let(:endpoint) { '/repos/github/bar/buzz/webhook' }
    let(:options) {{format: 'json'}}

    it "returns a 404 if it can't find the repo" do
      expect do
        post endpoint, push_event_body, options
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "with a repo" do
      before do
        repo
      end

      it "creates a build when it receives a push event" do
        expect do
          post endpoint, push_event_body, options
        end.to change{Build.count}.from(0).to(1)
      end

      it "creates a build when it receives a pull request event" do
        expect do
          post endpoint, pr_event_body, options
        end.to change{Build.count}.from(0).to(1)
      end

      it "does not create a build when it receives an event with a duplicate repo branch and sha" do
        post endpoint, push_event_body, options
        expect do
          post endpoint, pr_event_body, options
        end.to_not change{Build.count}
      end

      it "returns a 422 if it can't process the body" do
        post endpoint, "{{{{", options
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns a 422 if it can't process the body due to missing sha" do
        post endpoint, '{"ref": "refs/heads/master", "head_commit": {"id":""}}', options
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns a 422 if it can't process the body due to missing branch" do
        post endpoint, '{"ref": "", "head_commit": {"id": "abcdef"}}', options
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns a 422 if it can't process the body due to missing branch" do
        post endpoint, '{}', options
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns a 200 for ping events" do
        post endpoint, ping_event_body, options.merge('X-GitHub-Event' => 'ping')
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "#follow" do
    let(:user) { FactoryGirl.create(:user) }
    let(:repo) { FactoryGirl.create(:repo) }
    let(:repo_params) { repo.to_params }
    let(:repo_api_params) { repo.to_api_params }

    context "signed out" do
      it "redirects the user to sign in" do
        post :follow, repo_params, id: repo
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
            post :follow, repo_params
          end.to raise_error(ActionController::RoutingError)
        end
      end

      context "authorized" do
        it "creates a relationship between the user and the repo" do
          expect do
            post :follow, repo_params
          end.to change{UserRepo.count}.from(0).to(1)
        end

        it "redirects to the repo show page" do
          post :follow, repo_params
          expect(response).to redirect_to(new_repo_path)
        end
      end
    end
  end

  describe "#unfollow" do
    let(:user) { FactoryGirl.create(:user, repos: [repo] ) }
    let(:repo) { FactoryGirl.create(:repo) }
    let(:repo_params) { repo.to_params }
    let(:repo_api_params) { repo.to_api_params }

    context "signed out" do
      it "redirects the user to sign in" do
        post :unfollow, repo_params, id: repo
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
            post :unfollow, repo_params
          end.to raise_error(ActionController::RoutingError)
        end
      end

      context "authorized" do
        it "creates a relationship between the user and the repo" do
          expect do
            post :unfollow, repo_params
          end.to change{UserRepo.count}.from(1).to(0)
        end

        it "redirects to the repo show page" do
          post :unfollow, repo_params
          expect(response).to redirect_to(new_repo_path)
        end
      end
    end
  end
end
