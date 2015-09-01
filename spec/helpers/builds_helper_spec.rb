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

  describe "#build_duration" do
    it "returns N/A if the build hasn't started" do
      expect(build_duration(nil, nil)).to eq "N/A"
    end

    it "returns the passed duration if the build hasn't completed" do
      expect(build_duration(10.minutes.ago, nil)).to eq "10 minutes"
    end

    it "includes seconds" do
      expect(build_duration(18.seconds.ago, nil)).to eq "less than 20 seconds"
    end

    it "returns the duration once the build has completed" do
      start_time = 2.days.ago
      expect(build_duration(start_time, start_time + 50.minutes)).to eq "about 1 hour"
    end
  end
end
