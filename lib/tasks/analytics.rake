namespace :analytics do
  task :promobanner_counts => :environment do
    baseline_cache = Rails.root.join('tmp','last_promo_banner_counts.json')
    counts = PromotionBanner.all.collect{|b|
      b.attributes.slice('id', 'load_count', 'impression_count', 'click_count')
    }

    if File.exists? baseline_cache
      baseline = JSON.parse(File.read(baseline_cache))
      puts "Your action has made this difference in promo banners:"
      puts (baseline - counts).sort_by{|h| h['id']}
      puts (counts - baseline).sort_by{|h| h['id']}
    else
      puts "Establising Baseline"
      puts "Please take annother action to compare"
    end
    File.open(baseline_cache, 'w') {|f| f.write counts.to_json }
  end
end
