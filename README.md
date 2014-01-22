Knotweed
========================

Deployment
------------------------
Knotweed uses Capistrano to manage deployment. In order to be able to deploy from your user account, your public key must be added to /home/deploy/.ssh/authorized_keys. When you've made changes, merge them into master and push to Github. Then run 

    cap staging deploy

which will run migrations, precompile assets, and restart delayed job workers (of which there are currently two). Of note, the 'staging' environment is no longer in /home/nickg/knotweed-staging. There is a deploy user and staging releases are located in /home/deploy/knotweed. The nginx configuration is pointing to the current release at /home/deploy/knotweed/current/public.

Also of note, database.yml and application.yml are shared and not in the Git repository. If they need to be updated, the relevant ones are located in /home/deploy/knotweed/shared/config.
