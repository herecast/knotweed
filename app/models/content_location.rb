class ContentLocation < ActiveRecord::Base
  belongs_to :content
  belongs_to :location

  TYPES = ['base', 'about']

  TYPES.each do |type|

    scope type.to_sym,-> { where(location_type: type) }

    define_method "#{type}?" do
      type.eql? location_type
    end

    define_method "#{type}!" do
      self.location_type = type
      self.save!
    end

  end
end
