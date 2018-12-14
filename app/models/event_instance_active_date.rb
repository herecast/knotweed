class EventInstanceActiveDate
  include ActiveModel::Serialization
  attr_reader :date, :count

  def initialize(date: nil, count: nil)
    self.date = date
    self.count = count
  end

  def attributes
    { date: nil, count: nil }
  end

  def date=d
    if d.is_a? String
      @date = Date.parse(d)
    else
      @date = d
    end
  end

  def count=c
    if c.is_a? String
      @count = c.to_i
    else
      @count = c
    end
  end
end
