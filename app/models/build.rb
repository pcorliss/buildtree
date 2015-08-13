class Build < ActiveRecord::Base
  enum status: [ :queued, :success, :pending, :failure, :error ]

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

  def self.new_from_config(config, parent)
    Build.new(
      parent: parent,
      top_parent: parent.top_parent,
      env: config.env.to_json,
      parallel: config.parallel,
      repo: config.repo ? Repo.find_by(config.repo) : parent.repo,
      branch: config.branch,
      sha: parent.sha,
      sub_project_path: config.sub_project_path,
    )
  end
end
