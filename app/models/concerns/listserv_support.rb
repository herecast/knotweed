# frozen_string_literal: true

module ListservSupport
  extend ActiveSupport::Concern

  included do
    after_save :sync_mc_digest_name, if: :saved_change_to_mc_group_name?
    after_save :add_mc_webhook, if: :saved_change_to_mc_list_id?
  end

  def sync_mc_digest_name
    if mc_sync?
      old_name = mc_group_name_before_last_save
      if old_name.present?
        BackgroundJob.perform_later('MailchimpService', 'rename_digest',
                                    mc_list_id, old_name, mc_group_name)
      elsif mc_group_name.present?
        BackgroundJob.perform_later('MailchimpService', 'find_or_create_digest',
                                    mc_list_id, mc_group_name)
      end
    end
  end

  def add_mc_webhook
    BackgroundJob.perform_later('MailchimpService', 'add_unsubscribe_hook', mc_list_id) if mc_list_id.present?
  end
end
