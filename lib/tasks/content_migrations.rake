namespace :content_migrations do
  desc 'Remove Listserv content'
  task remove_list_content: :environment do
    # remove antiquated Listserv content
    Content.where(organization_id: Organization::LISTSERV_ORG_ID)
           .find_in_batches(batch_size: 100) do |batch|
      sleep 4
      BackgroundJob.perform_later('DeleteBatchOfContent', 'call', batch)
    end
  end

  desc 'Remove Valley News content'
  task remove_vn_content: :environment do
    # remove unusable Valley News content
    # the redundant ID check here is to ensure we get the right Org
    v_news = Organization.find_by(name: 'The Valley News', id: 4)

    Content.where(organization_id: v_news.id)
           .find_in_batches(batch_size: 100) do |batch|
      sleep 4
      BackgroundJob.perform_later('DeleteBatchOfContent', 'call', batch)
    end
  end
end