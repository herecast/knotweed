class DeleteBatchOfContent
  def self.call(batch)
    batch.each(&:destroy)
  end
end
