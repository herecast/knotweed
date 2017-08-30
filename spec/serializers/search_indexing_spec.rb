require 'spec_helper'


describe 'Content seralization for elasticsearch indexing' do
  # Searchkick uses #search_data to construct the document in elasticsearch
  subject { content.search_data }

  shared_examples_for 'Serialized Content for Search' do
    it 'has the expected fields for all content' do
      expect(subject).to include(
        id: content.id,
        title: content.title,
        subtitle: content.subtitle,
        content: content.sanitized_content,
        author_name: content.author_name,
        pubdate: content.pubdate,
        all_loc_ids: content.all_loc_ids,
        base_location_ids: content.base_locations.map(&:id),
        about_location_ids: content.about_locations.map(&:id),
        published: content.published,
        channel_type: content.channel_type,
        channel_id: content.channel_id,
        content_type: content.content_type,
        root_content_category_id: content.root_content_category_id,
        content_category_id: content.content_category_id,
        my_town_only: content.my_town_only,
        deleted: content.deleted_at?,
        root_parent_id: content.root_parent_id,
        in_accepted_category: be(true).or(be(false)),
        is_listserv_market_post: content.is_listserv_market_post?,
        organization_id: content.organization_id,
        organization_name: content.organization.name,
        created_at: content.created_at,
        updated_at: content.updated_at,
        biz_feed_public: content.biz_feed_public?,
        view_count: content.view_count || content.parent_view_count,
        commenter_count: content.commenter_count,
        comment_count: content.comment_count,
        parent_id: content.parent_id,
        parent_content_type: content.parent.present? ? content.parent.content_category.name : nil,
        sunset_date: content.sunset_date,
        organization: {
          id: content.organization.id,
          name: content.organization.name,
          profile_image_url: content.organization.profile_image_url,
          biz_feed_active: content.organization.biz_feed_active
        },
        created_by: {
          id: content.created_by.id,
          name: content.created_by.name,
          avatar_url: content.created_by.avatar_url
        },
        images: content.images.map do |image|
          {
            id: image.id,
            image_url: image.image.url,
            primary: image.primary?,
            width: image.width,
            height: image.height,
            file_extension: image.file_extension,
            position: image.position,
            created_at: image.created_at
          }
        end,
        content_locations: content.content_locations.map do |cl|
          {
            id: cl.id,
            location_id: cl.location.id,
            location_type: cl.location_type,
            location: {
              id: cl.location.id,
              slug: cl.location.slug,
              name: cl.location.name,
              city: cl.location.city,
              state: cl.location.state,
              zip: cl.location.zip
            }
          }
        end
      )
    end
  end

  describe 'News content' do
    let(:content) {
      FactoryGirl.create :content, :news,
        created_by: FactoryGirl.create(:user),
        images: FactoryGirl.create_list(:image, 2),
        content_locations: FactoryGirl.create_list(:content_location, 2)
    }

    it_behaves_like 'Serialized Content for Search'
  end

  describe 'Talk content' do
    let(:content) {
      FactoryGirl.create :content, :talk,
        created_by: FactoryGirl.create(:user),
        images: FactoryGirl.create_list(:image, 2),
        content_locations: FactoryGirl.create_list(:content_location, 2)
    }

    it_behaves_like 'Serialized Content for Search'
  end

  describe 'Market content' do
    let(:content) {
      FactoryGirl.create :content, :market_post,
        created_by: FactoryGirl.create(:user),
        images: FactoryGirl.create_list(:image, 2),
        content_locations: FactoryGirl.create_list(:content_location, 2)
    }

    it_behaves_like 'Serialized Content for Search'

    it 'has additional market related fields' do
      expect(subject).to include(
        sold: content.channel.sold,
        cost: content.channel.cost,
        contact_phone: content.channel.contact_phone,
        contact_email: content.channel.contact_email
      )
    end
  end

  describe 'Event content' do
    let(:content) {
      FactoryGirl.create :content, :event,
        created_by: FactoryGirl.create(:user),
        images: FactoryGirl.create_list(:image, 2),
        content_locations: FactoryGirl.create_list(:content_location, 2)
    }

    it_behaves_like 'Serialized Content for Search'

    it 'has additional event related fields' do
      expect(subject).to include(
        cost: content.channel.cost,
        cost_type: content.channel.cost_type,
        contact_phone: content.channel.contact_phone,
        contact_email: content.channel.contact_email,
        venue: {
          id: content.channel.venue.id,
          name: content.channel.venue.name,
          address: content.channel.venue.address,
          city: content.channel.venue.city,
          state: content.channel.venue.state,
          zip: content.channel.venue.zip,
          venue_url: content.channel.venue.venue_url
        },
        event_instances: content.channel.event_instances.map do |inst|
          {
            id: inst.id,
            start_date: inst.start_date,
            end_date: inst.end_date,
            subtitle_override: inst.subtitle_override,
            description_override: inst.description_override,
            presenter_name: inst.presenter_name
          }
        end
      )
    end
  end
end
