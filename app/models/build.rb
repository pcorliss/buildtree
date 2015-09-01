class Build < ActiveRecord::Base
  enum status: [ :queued, :success, :pending, :failure, :error ]

  STATUS_HIERARCHY = [:error, :failure, :pending, :queued, :success]

  belongs_to :repo
  has_many :build_logs

  belongs_to :parent, foreign_key: :parent_id, class_name: Build
  has_many :children, foreign_key: :parent_id, class_name: Build

  def short_sha
    self.sha.first(7) if self.sha
  end

  def enqueue!
    Delayed::Job.enqueue BuildJob.new(self)
  end

  def overall_status
    statuses = children_statuses << self.status
    statuses.uniq!
    STATUS_HIERARCHY.each do |status|
      return status.to_s if statuses.include?(status.to_s)
    end
    return self.status
  end

  def children_statuses
    self.children.map do |child|
      child.overall_status
    end
  end

  def overall_completed_at
    completed_ats = children_completed_at << self.completed_at
    return nil if completed_ats.any? { |c| c.nil? }
    completed_ats.max
  end

  def children_completed_at
    self.children.map(&:overall_completed_at)
  end

  def self.new_from_config(config, parent)
    repo = config.repo ? Repo.find_by(config.repo) : parent.repo
    return nil unless repo

    Build.new(
      parent: parent,
      env: config.env.to_json,
      parallel: config.parallel,
      # TODO this should find_or_create_by
      # TODO what happens when this is a public repo?
      # TODO can we differentiate the two effectively
      repo: repo,
      branch: config.branch,
      sha: config.sub_project_path ? parent.sha : nil,
      sub_project_path: config.sub_project_path,
    )
  end
end
