class Build < ActiveRecord::Base
  belongs_to :repo
  has_many :build_logs

  def short_sha
    self.sha.first(7) if self.sha
  end

  def enqueue!
    Delayed::Job.enqueue BuildJob.new(self)
  end
end
