namespace :channels do 
  
  task :setup_default_channels => :environment do
    { "News" => ["Local & Leisure", "Front", "Reporters", "Special", "Sunday",
                  "World/Nation", "home"], 
    "Talk of the Town" => ["Opinion"], 
    "Marketplace" => [], 
    "Sports" => ["Sports"], 
    "Life" => ["Business", "Business & Travel", "Closeup", "Life and Leisure",
                  "Obituaries", "TAB", "travel", "zProduction"],
    "Calendar" => ["Calendar"]}.each do |name, categories|
      c = Channel.find_by_name(name)
      if c.nil?
        c = Channel.new
        c.name = name
      end
      categories.each do |cat|
        unless c.categories.include? cat
          c.categories << cat
        end
      end
      c.save
    end
  end
  
end