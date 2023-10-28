---
layout: post
title: "Delayed Job Exception Notification Integration"
date: 2014-05-03
comments: true
tags: [Ruby, Rails, Tools]
---
We are using [delayed_job](https://github.com/collectiveidea/delayed_job) for background jobs and didn't see a built-in option to send email notifications when a job failed. Since we were already using [exception_notification](https://github.com/smartinez87/exception_notification) to email application exceptions, we thought it would be nice to integrate that.

With some code from [here](http://stackoverflow.com/a/6170366/126688) and [here](http://kreusch.com.br/blog/2012/01/13/notifying-delayed-job-failures-by-default/), we put together the initializer below and created a email template in `app/views/exception_notifier/_delayed_job.text.erb` per the instructions.

We have this running in production now. Each of our Delayed Jobs are set up as classes and use the [failure](https://github.com/collectiveidea/delayed_job#hooks) hook. We are now receiving email notifications of job failures and it helps us resolve them quickly!

```ruby
# Chain delayed job's handle_failed_job method to do exception notification
Delayed::Worker.class_eval do
  def handle_failed_job_with_notification(job, error)
    handle_failed_job_without_notification(job, error)

    # only actually send mail in production
    if Rails.env.production?
      # rescue if ExceptionNotifier fails for some reason
      begin
        env = {}
        env['exception_notifier.options'] = {
          :sections => %w(backtrace delayed_job),
          :email_prefix => '[Delayed Job ERROR] ',
          :exception_recipients => %w(engineering@yourcompany.com),
          :sender_address => %(postmaster@yourcompany.com)
        }
        env['exception_notifier.exception_data'] = {:job => job}
        ::ExceptionNotifier::Notifier.exception_notification(env, error).deliver

      rescue Exception => e
        Rails.logger.error "ExceptionNotifier failed: #{e.class.name}: #{e.message}"

        e.backtrace.each do |f|
          Rails.logger.error "  #{f}"
        end

        Rails.logger.flush
      end
    end
  end

  alias_method_chain :handle_failed_job, :notification
end
```
