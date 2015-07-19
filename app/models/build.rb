class Build < ActiveRecord::Base
  belongs_to :repo

  def short_sha
    self.sha.first(7) if self.sha
  end
end