class BackgroundJob < ApplicationJob
  def perform(klass, method, *args)
    klass.constantize.send(method, *args)
  end
end
