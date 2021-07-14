---
layout: page
permalink: /software-dev-process
title: Software Development Process
---

## Back-end Development

### Discovery Questions

Here are some questions I find helpful to think about to discovery requirements or dependencies in the process of building new back-end features or services.

These questions should be asked as early as possible as to minimize re-work.

- Does it require database changes?
- Does it require backfilling data that didn't exist prior to a certain date that the feature depends on?
- Does it require a new API endpoint or the modification of an existing one?
- Is there a rough idea of the API request payload? Required or optional attributes?
- Is there a rough idea of the API response payload?
- Performance concerns (slow queries, external service calls, payload size)
- Any inter-service calls expected?
- Any external service calls expected?
- Are there dependencies or pre-requisites that can be identified now? (e.g. data sources, API plumbing, account establishment)
- Can a trial or test account be used for a vetting process?


### Pull Request Template

Here are some checkboxes to help evaluate my own changes before requesting a code review from others.

- This PR has Security and Privacy Concerns or Personally-identifying information I've addressed
- I have updated corresponding API documentation
- My changes do not generate new warnings (Rails: boot app with `$VERBOSE = true` somewhere, e.g. `config/application.rb`)
- I have added corresponding test code that demonstrates that my feature or fix works as intended
- I have added required environment variables to all environments
- I explained why this change is happening in the PR desc or associated ticket

### Development Flow

- Write some code on a feature branch
- Write positive and negative test cases for the code to confirm it's working as expected
- Plan for any backwards compatibility, add more code and tests
- When the CI suite passes, ship the code to a pre-production environment for further integration testing
- When integration testing is complete, ship to production. Integrate main branch changes into feature branch frequently.
- Repeat

