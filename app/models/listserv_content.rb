# == Schema Information
#
# Table name: listserv_contents
#
#  id                         :integer          not null, primary key
#  listserv_id                :integer
#  sender_name                :string
#  sender_email               :string
#  subject                    :string
#  body                       :text
#  content_category_id        :integer
#  subscription_id            :integer
#  key                        :string
#  verification_email_sent_at :datetime
#  verified_at                :datetime
#  pubdate                    :datetime
#  content_id                 :integer
#  user_id                    :integer
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  verify_ip                  :string
#

class ListservContent < ActiveRecord::Base
  belongs_to :listserv
  belongs_to :content_category
  belongs_to :subscription
  belongs_to :content
  belongs_to :user

  validates :key, presence: true, uniqueness: true
  after_initialize :generate_key, unless: :key

  validates :listserv, :sender_email, :body, :subject, presence: true

  validates :verify_ip, presence: true, if: :verified?

  def self.find(id)
    find_by!("#{table_name}.id = :id OR #{table_name}.key = :key", id: id.to_i, key: id.to_s)
  end

  scope :verified, -> {
    where('verified_at IS NOT NULL')
  }

  scope :sender_email_like, -> (text){
    where('sender_email LIKE ?', "%#{text}%")
  }

  scope :subject_like, -> (text){
    where('subject LIKE ?', "%#{text}%")
  }

  def sender_email=e
    write_attribute :sender_email, e.try(:downcase)
  end

  def categorized?
    content_category_id?
  end

  def verified?
    verified_at?
  end

  def published?
    pubdate?
  end

  def ascii_body
    if body.present?
      body.encode(Encoding.find('ASCII'), {
          :invalid => :replace,
          :undef => :replace,
          :replace => ""
      })
    else
      ""
    end
  end

  def publish_content(include_tags=false)
    if include_tags
      ascii_body
    else
      strip_tags(ascii_body)
    end
  end

  def feature_set
    {
      "title" => subject,
      "source" => "Listserv",
      "classify_only" => true
    }
  end

  def document_uri
    # tbd?
    ''
  end

  def to_xml(include_tags=false)
    ContentDspSerializer.new(self).to_xml(include_tags)
  end

  def channel_type
    prefix = nil
    if content_category
      prefix = category_top(content_category).name
    end

    # convert talk_of_the_town to talk
    prefix = 'talk' if prefix == 'talk_of_the_town'
    prefix ? prefix.to_sym : nil
  end

  def channel_type=t
    cat_name = t.to_s
    cat_name = 'talk_of_the_town' if t.to_s == 'talk'
    if cat_name != channel_type.to_s
      self.content_category = ContentCategory.find_by(name: cat_name)
    end
  end

  protected
  def generate_key
    self.key = SecureRandom.uuid
  end

  def category_top(cat)
    cat.parent ? category_top(cat.parent) : cat
  end
end
