---
layout: page
permalink: /sidekiq
title: Sidekiq Tips
---

## Sidekiq

### Remove all jobs for queue

`Sidekiq::Queue.new.clear`

### Removing specific jobs from a queue

From the [Sidekiq API](https://github.com/mperham/sidekiq/wiki/API), jobs can be deleted by:

* Class type
* Arguments
* Job ID

```
queue = Sidekiq::Queue.new("mailer")
queue.each do |job|
  job.klass # => 'MyWorker'
  job.args # => [1, 2, 3]
  job.delete if job.jid == 'abcdef1234567890'
end
```

### Check the latency for a queue

`Sidekiq::Queue.new("mailer").latency`


### Inspecting runtime stats

Default queue latency: `Sidekiq::Stats.new.default_queue_latency`
Retry queue latency: `Sidekiq::Queue.new('retry').latency`

### Processes and Workers

The processes that Sidekiq currently has configured.

`Sidekiq::ProcessSet.new`

> A 'worker' is defined as a thread currently processing a job

`Sidekiq::Workers.new`


### Sidekiq testing

<https://github.com/mperham/sidekiq/wiki/Testing> We use the `inline!` method to test jobs synchronously.
