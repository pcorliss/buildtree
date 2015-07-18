require 'rails_helper'

describe ReposController do
  context "routing" do
    it "routes to #new" do
      expect(get: "/repo/new").to route_to("repos#new")
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
    end
  end
end
