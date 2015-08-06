class Build < ActiveRecord::Base
  belongs_to :repo
  has_many :build_logs

  belongs_to :parent, foreign_key: :parent_id, class_name: Build
  has_many :children, foreign_key: :parent_id, class_name: Build

  belongs_to :top_parent, foreign_key: :top_parent_id, class_name: Build
  has_many :descendents, foreign_key: :top_parent_id, class_name: Build

  def short_sha
    self.sha.first(7) if self.sha
  end

  def enqueue!
    Delayed::Job.enqueue BuildJob.new(self)
  end

  def set_hosting_status!(git_api = nil)
  end
end
