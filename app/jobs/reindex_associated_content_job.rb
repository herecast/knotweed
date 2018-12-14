class ReindexAssociatedContentJob < ApplicationJob
  # The following options are already set in the
  # global sidekiq config.  If they were not, we would need
  # to make sure they were set for this job.
  # sidekiq_options unique: :until_and_while_executing

  def perform(object)
    object.contents.find_each do |content|
      # for comments we want to reindex the parent, not the comment
      if content.parent.present?
        to_reindex = content.parent
      else
        to_reindex = content
      end
      logger.info "Reindexing content with ID #{to_reindex.id}"
      to_reindex.reindex
    end
  end
end
