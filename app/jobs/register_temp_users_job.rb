class RegisterTempUsersJob < ApplicationJob
  Knotweed::Application.load_tasks
  def perform
    Rake::Task['temp_users:register'].execute
  end
end
