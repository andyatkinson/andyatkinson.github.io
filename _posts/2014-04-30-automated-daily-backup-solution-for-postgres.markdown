---
layout: post
title: "Automated Daily Backup Solution for PostgreSQL"
date: 2014-04-30
comments: true
tags: [Productivity, PostgreSQL, Databases, Tips]
---

A Ruby gem called [safe](https://github.com/astrails/safe) provides a DSL for generating the commands to perform the backup. We used [this fork](https://github.com/mattberther/safe) which fixed some AWS issues.

The gist of what safe does is run `pg_dump` to create a backup file, encrypt it, then push it to Amazon S3. We added a command to run the script daily.

We also use the [whenever](https://github.com/javan/whenever) gem to generate our crontab file. Our configuration is below, see GitHub for the complete set of options. Encryption via gpg can use public and private keys, or a simple passphrase.

```rb
safe do
  local :path => "/tmp/backups/:kind/:id"

  s3 do
    key s3['access_key_id']
    secret s3['secret_access_key']
    bucket "my-backups"
    path ":kind/:id"
  end

  gpg do
    command "/usr/bin/gpg"
    options  "--no-use-agent --no-tty"
    password "test1234"
  end

  keep do
    local 10
    s3 20
  end

  pgdump do
    options "-i -x -O"
    user your_db_user
    database :your_database
  end
end
```

The variables like `s3` in our configuration are coming from config files in the app. The database config could be loaded like this:

```rb
require "yaml"
db = YAML.load_file(File.join(Dir.getwd, 'config', 'database.yml'))[environment]
```

## Deployment
Once the safe configuration file is specified, the `astrails-safe` executable can be run. We use cron to run this once a day. The whenever gem supplies a `config/schedule.rb` for crontab entries. The `whenever` command can be run to see what will be generated. Whenever also provides Capistrano tasks to update the crontab file on every deploy.

We used the `job_template` option to so that the command was run from the app directory and is run with `bundle exec`.

```rb
every 1.day, :at => '4:30 am' do
  set :job_template, "cd :path && RAILS_ENV=production :task"
  command "bundle exec astrails-safe -v config/database_backup.rb >/dev/null 2>&1"
end
```

## Conclusion
This script has been running for a few days so far and is meeting our needs.
