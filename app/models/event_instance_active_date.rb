# frozen_string_literal: true

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

  def date=(d)
    @date = if d.is_a? String
              Date.parse(d)
            else
              d
            end
  end

  def count=(c)
    @count = if c.is_a? String
               c.to_i
             else
               c
             end
  end
end
