class Build < ActiveRecord::Base
  enum status: [ :queued, :success, :pending, :failure, :error ]
  enum build_status: [ :build_queued, :build_success, :build_pending, :build_failure, :build_error ]

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

  end
end
