class ListservDigestPreview < ActionMailer::Preview
  def digest
    ListservDigestMailer.digest(ListservDigest.last)
  end
end
