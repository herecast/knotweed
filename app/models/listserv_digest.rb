class ListservDigest < ActiveRecord::Base
  belongs_to :listserv
  serialize :listserv_content_ids, Array
  serialize :content_ids, Array

  def listserv_contents=contents
    self.listserv_content_ids = contents.map(&:id)
    @listserv_contents = contents
  end

  def listserv_contents
    @listserv_contents ||=
      listserv_content_ids.any? ?
        ListservContent.where(id: listserv_content_ids) : []
  end

  def contents=contents
    self.content_ids = contents.map(&:id)
    @contents = contents
  end

 def contents
    @contents ||=
      content_ids.any? ?
        Content.where(id: content_ids).sort_by{|c| content_ids.index(c.id)} : []
  end
end
