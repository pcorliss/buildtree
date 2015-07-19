require 'rails_helper'

describe AuthsController do
  context "routing" do
    it "routes to #create" do
      expect(get: "/auth/foo/callback").to route_to(
        "auths#create",
        provider: 'foo'
      )
    end

    it "routes to #new" do
      expect(get: "/auth/signin").to route_to("auths#new")
    end

    it "routes to #destroy" do
      expect(get: "/auth/signout").to route_to("auths#destroy")
    end
  end

  describe "#create" do
    before do
      request.env['omniauth.auth'] = callback
    end

    context "valid callback" do
      let(:callback) { JSON.parse File.read("spec/fixtures/github_callback.json") }
      let(:uid)      { callback['uid'] }
      let(:provider) { callback['provider'] }

      it "creates a user from the auth_hash" do
        expect do
          get :create, provider: 'github'
        end.to change{ User.count }.by(1)
      end

      it "finds an existing user from the auth_hash and updates" do
        user = User.find_or_create_from_auth_hash(callback)
        user.update_attributes(name: 'Bob Smith')
        expect do
          get :create, provider: 'github'
        end.to_not change{ User.count }
        expect(user.reload.name).to eq('Philip Corliss')
      end

      #it "redirects to the user dashboard" do
        #get :create, provider: 'github'
        #expect(response).to redirect_to(user_dashboard_path("#{provider}_#{uid}"))
      #end

      it "sets the flash success" do
        get :create, provider: 'github'
        expect(flash[:success]).to eq(['Signed In'])
      end

      it "sets the user_id on the session" do
        get :create, provider: 'github'
        expect(session[:user_id]).to eq(User.last.id)
      end
    end

    # Note: Unable to get here via manual testing.
    context "invalid callback" do
      let(:callback) { {} }

      it "redirects to signin on error" do
        get :create, provider: 'github'
        expect(response).to redirect_to(signin_auth_path)
      end

      it "sets the flash on error" do
        get :create, provider: 'github'
        expect(flash[:error]).to eq(['Unable to login with github'])
      end
    end
  end

  describe "#destroy" do
    it "redirects to #new" do
      get :destroy
      expect(response).to redirect_to(signin_auth_path)
    end

    it "destroys the current session" do
      session['fizz'] = 'buzz'
      get :destroy
      expect(session['fizz']).to be_nil
    end

    it "sets the flash" do
      get :destroy
      expect(flash[:success]).to eq(['You have successfully logged out.'])
    end
  end

  describe "#new" do
    it "displays a flash message if you are already logged in" do
      user = FactoryGirl.create(:user)
      session[:user_id] = user.id
      get :new
      expect(flash[:warning]).to eq(["You are already logged in."])
    end
  end
end
