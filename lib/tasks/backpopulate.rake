# frozen_string_literal: true

namespace :backpopulate do
  task root_parent_ids: :environment do
    puts 'Updating all Content records where parent_id: nil and root_parent_id: nil'
    # to make this more efficient, we're updating all root parents first
    # with a single SQL query, then cycling through the remaining ones.
    # In other words, this handles more than 300,000 records, allowing the next
    # part to only iterate through a few thousand.
    Content.where(root_parent_id: nil, parent_id: nil).update_all('root_parent_id = id')
    puts "Updating child contents, #{Content.where(root_parent_id: nil).count}"
    Content.where(root_parent_id: nil).each do |c|
      c.update_column :root_parent_id, c.find_root_parent.id
    end
  end

  task fix_orphaned_promotion_listservs: :environment do
    puts 'Updating all orphaned promotion listserv records'
    fixed = 0
    skipped = 0
    Promotion.where(promotable: nil).find_each do |p|
      date_range = p.created_at..(p.created_at + 2.seconds)
      pl = PromotionListserv.where(created_at: date_range)
                            .where('(select count(id) from promotions where promotable_type=? and promotable_id=promotion_listservs.id)=0', 'PromotionListserv').first
      if pl.present?
        puts "attaching promotion #{p.id} to promotion listserv #{pl.id}\n"
        p.promotable = pl
        p.save
        fixed += 1
      else
        puts "unable to find promotion listserv for promotion #{p.id}\n"
        skipped += 1
      end
    end
    puts "attached #{fixed} promotions to promotion listservs\n"
    puts "skipped #{skipped} promotions\n"
  end
end
