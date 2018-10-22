module ListservSupport

  extend ActiveSupport::Concern

  included do
    after_save :sync_mc_digest_name, if: :saved_change_to_mc_group_name?
    after_save :add_mc_webhook, if: :saved_change_to_mc_list_id?
  end

  def sync_mc_digest_name
    if mc_sync?
      old_name = self.mc_group_name_before_last_save
      if old_name.present?
        BackgroundJob.perform_later('MailchimpService', 'rename_digest',
                                 self.mc_list_id, old_name, self.mc_group_name)
      elsif self.mc_group_name.present?
        BackgroundJob.perform_later('MailchimpService', 'find_or_create_digest', 
                                    self.mc_list_id, self.mc_group_name)
      end
    end
  end

  def add_mc_webhook
    BackgroundJob.perform_later('MailchimpService', 'add_unsubscribe_hook', self.mc_list_id) if self.mc_list_id.present?
  end
end
