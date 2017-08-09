class ReindexOrganizationContentJob < ApplicationJob
  # The following options are already set in the
  # global sidekiq config.  If they were not, we would need
  # to make sure they were set for this job.
  #sidekiq_options unique: :until_and_while_executing

  def perform(organization)
    organization.contents.find_each do |content|
      content.reindex
    end
  end
end
