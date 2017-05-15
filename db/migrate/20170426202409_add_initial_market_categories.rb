class AddInitialMarketCategories < ActiveRecord::Migration
  def change
    add_column :event_categories, :slug, :string

    categories = {
      family_fun:      ["Family Friendly", "kid-friendly family children", "OR"],
      wellness:        ["Wellness", "yoga exercise wellness health fitness", "OR"],
      outdoor:         ["Outdoor", "outdoor hike hiking bike biking run garden walk", "OR"],
      music:           ["Music", "chorus choral music concert instruments", "OR"],
      food:            ["Food", "food restaurant breakfast brunch lunch dinner vegetables meat", "OR"],
      arts:            ["Arts", "art gallery performance", "OR"],
      sports:          ["Sports", "sports baseball basketball soccer hockey lacrosse walk race", "OR"],
      yard_sales:      ["Yard Sales", "'yard sale' 'garage sale' 'neighborhood sale'", "OR"],
      farmers_markets: ["Farmers Markets", "farmers market", "AND"],
      festivals:       ["Festivals", "fair carnival festival", "OR"],
      nightlife:       ["Night Life", "music drinks nightlife concert dancing wine beer", "OR"],
      movies:          ["Movies", "movie cinema showtime film nugget", "OR"]
    }

    categories.each do |key, array|
      EventCategory.create(
        name: array[0],
        slug: key.to_s,
        query: array[1],
        query_modifier: array[2]
      )
    end
  end
end