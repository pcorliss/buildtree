require 'rails_helper'

describe HomeController do
  context "routing" do
    it "routes to #index" do
      expect(get: "/").to route_to(
        :controller => "home",
        :action => "index",
      )
    end
  end

  describe "#index" do
    let(:user) { FactoryGirl.create(:user) }

    context "signed out" do
      it "redirects the user to sign in" do
        get :index
        expect(flash[:error]).to eq(["Please log in"])
        expect(response).to redirect_to(signin_auth_path)
      end
    end

    context "signed in" do
      before do
        session[:user_id] = user.id
      end

      # We explicitly allow all logged in users to view other users dashboards
      it "redirects to the user dash" do
        get :index
        expect(response).to redirect_to(user_path(user))
      end
    end
  end
end
