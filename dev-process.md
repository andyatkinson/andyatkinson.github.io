---
layout: page
permalink: /software-dev-process
title: Software Development Process
---

## Back-end Web Development

### Questions

Here are some questions I find helpful to think about in the process of building new back-end features or services.

These questions could be asked in the design stage, or in the code review stage.

- Does it require database changes?
- Does it require backfilling data that didn't exist prior to a certain date that the feature depends on?
- Does it require a new API endpoint or the modification of an existing one?
- Is there a rough idea of the API request payload? Required or optional attributes?
- Is there a rough idea of the API response payload. 
- Performance concerns (slow queries, external service calls, payload size)
- Any inter-service calls expected?
- Any external service calls expected?


### Pull Request Template

Here are some checkboxes to help evaluate my own changes before requesting a code review from others.

- This PR has Security and Privacy Concerns or Personally-identifying information I've addressed
- I have updated corresponding API documentation
- My changes do not generate new warnings (Rails: boot app with `$VERBOSE = true` somewhere, e.g. `config/application.rb`)
- I have added corresponding test code that demonstrates that my feature or fix works as intended
- I have added required environment variables to all environments
- I explained why this change is happening in the PR desc or associated ticket
