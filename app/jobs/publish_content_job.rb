class PublishContentJob < ApplicationJob
  def perform(content, repo=Repository.production_repo, method=Content::DEFAULT_PUBLISH_METHOD)
    content.publish(method, repo)
  end
end
