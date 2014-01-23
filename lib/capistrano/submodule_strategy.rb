module SubmoduleStrategy
  # do all the things a normal capistrano git session would do
  include Capistrano::Git::DefaultStrategy

  # check for a .git directory
  def test
    test! " [ -d #{repo_path}/.git ] "
  end

  # make sure to move your existing bare repo out of the way
  def clone
    git :clone, '-b', fetch(:branch), '--recursive', repo_url, repo_path
  end

  # put the working tree in a release-branch,
  # make sure the submodules are up-to-date
  # and copy everything to the release path
  #
  def release
    release_branch = fetch(:release_branch, File.basename(release_path))
    git :checkout, '-b', release_branch, fetch(:remote_branch, "origin/#{fetch(:branch)}")
    git :submodule, :update, '--init'
    execute "tar --exlude=.git\* -cf - . | (cd #{release_path} && tar -xf - )"
  end
end