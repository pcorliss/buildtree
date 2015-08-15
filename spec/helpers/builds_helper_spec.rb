require 'rails_helper'

describe BuildsHelper do
  describe "#builds_status" do
    it "returns a pending status icon" do
      expect(build_status('pending')).to include('fa-cog fa-spin')
    end

    it "returns a queued status icon" do
      expect(build_status('queued')).to include('fa-clock-o')
    end

    it "returns a success status icon" do
      expect(build_status('success')).to include('fa-check')
      expect(build_status('success')).to include('text-success')
    end

    it "returns a failure status icon" do
      expect(build_status('failure')).to include('fa-times')
      expect(build_status('failure')).to include('text-danger')
    end

    it "returns an error status icon" do
      expect(build_status('error')).to include('fa-exclamation-triangle')
      expect(build_status('error')).to include('text-danger')
    end

    it "returns an error status icon for everything else" do
      expect(build_status('asdf')).to include('fa-exclamation-triangle')
      expect(build_status('asdf')).to include('text-danger')
    end
  end
end
