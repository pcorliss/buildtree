require 'rails_helper'

describe ReposController do
  context "routing" do
    it "routes to #new" do
      expect(get: "/repos/new").to route_to("repos#new")
    end

    it "routes to #create" do
      expect(post: "/repos").to route_to("repos#create")
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

      before do
        session[:user_id] = user.id
      end

      it "Usees the API to grab the users repos" do
        repos = []
        expect_any_instance_of(GitApi).to receive(:repos).and_return(repos)
        get :new
      end

      xit "TODO It notes repos already in the system"
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
      let(:valid_params) {{ service: "github", owner: "foo", name: "bar" }}
      let(:private_params) {{ service: "github", owner: "pcorliss", name: "design_patterns" }}
      let(:repo) { Repo.initialize_by_api(Hashie::Mash.new(valid_params)).save }

      before do
        session[:user_id] = user.id
        repos = [Hashie::Mash.new(valid_params), Hashie::Mash.new(private_params)]
        allow_any_instance_of(GitApi).to receive(:repos).and_return(repos)
        allow_any_instance_of(GitApi).to receive(:github_add_key)
        allow_any_instance_of(GitApi).to receive(:deploy_key_exists?).and_return(false)
      end

      it "creates a repo" do
        expect do
          post :create, repo: valid_params
        end.to change{Repo.count}.from(0).to(1)
      end

      it "doesn't create a repo that already exists" do
        repo
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

      it "TODO creates a webhook"

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

      it "TODO updates a repo if it's not setup properly"
      it "BLOCKED ON BUILD creates a build"
      it "BLOCKED ON BUILD redirects to the build show page"
    end
  end

end
