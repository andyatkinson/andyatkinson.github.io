---
layout: page
permalink: /10-mistakes
title: 10 Mistakes
---

# 10 Costly Database Performance Mistakes
## (And How to Fix Them)
Slides: <https://github.com/andyatkinson/presentations>

## Book Giveaway
1. Sign up for my newsletter on Postgres and Rails at <https://pgrailsbook.com> and confirm
1. Once confirmed, reply to the email with "enter me into the book contest"

That's it! I'll reply back to you and if you win, I'll find you at RailsConf to give you your book copy!

See other readers who got their copies 👉 <br/>
[📚 Readers get their copies of "High Performance PostgreSQL for Rails"](https://andyatkinson.com/blog/2024/07/23/high-performance-postgresql-for-rails-readers-getting-books)


## Bonus Content
## RailsConf 2025: The Past, the Present, and the Future of Rails
- Past: 1970s![^1]
- Present: PostgreSQL, MySQL, SQLite, *2024 Rails Survey*,[^survey] 2700 responses
- Future: PostgreSQL, MySQL, SQLite, in top 10 of *424* per *db-engines*[^dbeng]

![bg contain right 90%](/assets/images/pages/db-engines-10-small.jpg)

## rails_best_practices gem
![rails_best_practices gem 90%](/assets/images/pages/rbp.jpg)
<small>rails_best_practices gem</small>

[^1]: <https://ibm.com/history/relational-database>
[^survey]: <https://railsdeveloper.com/survey/2024/#databases>
[^dbeng]: <https://db-engines.com/en/ranking>


## Footnote Links

<style type="text/css">
section li, section li a {
  font-size:11px;
}
.footnote {
  position:relative;
}
ul {
  list-style-type:none;
  margin-left:-5px;
}
ul.two-column-list {
  column-count: 2;
  column-gap: 2rem;
  padding: 0;
  list-style-position: inside;
}
</style>
<section>
<div class='footnote'><ul class='two-column-list'><li id='footnote-1'>
  1. <a href='https://railsdeveloper.com/survey/2024/#databases'>railsdeveloper.com/survey/2024/#databases</a>
</li>
<li id='footnote-2'>
  2. <a href='https://db-engines.com/en/ranking'>db-engines.com/en/ranking</a>
</li>
<li id='footnote-3'>
  3. <a href='https://railsdeveloper.com/survey/2024/#deployment-devops'>railsdeveloper.com/survey/2024/#deployment-devops</a>
</li>
<li id='footnote-4'>
  4. <a href='https://dora.dev/guides/dora-metrics-four-keys'>dora.dev/guides/dora-metrics-four-keys</a>
</li>
<li id='footnote-5'>
  5. <a href='https://octopus.com/devops/metrics/space-framework'>octopus.com/devops/metrics/space-framework</a>
</li>
<li id='footnote-6'>
  6. <a href='https://postgres.fm/episodes/over-indexing'>postgres.fm/episodes/over-indexing</a>
</li>
<li id='footnote-7'>
  7. <a href='https://github.com/djezzzl/database_consistency'>github.com/djezzzl/database_consistency</a>
</li>
<li id='footnote-8'>
  8. <a href='https://andyatkinson.com/generating-short-alphanumeric-public-id-postgres'>andyatkinson.com/generating-short-alphanumeric-public-id-postgres</a>
</li>
<li id='footnote-10'>
  10. <a href='https://andyatkinson.com/tip-track-sql-queries-quantity-ruby-rails-postgresql'>andyatkinson.com/tip-track-sql-queries-quantity-ruby-rails-postgresql</a>
</li>
<li id='footnote-11'>
  11. <a href='https://andyatkinson.com/blog/2024/05/28/top-5-postgresql-surprises-from-rails-developers#4-enumerating-columns-vs-select'>andyatkinson.com/blog/2024/05/28/top-5-postgresql-surprises-from-rails-developers#4-enumerating-columns-vs-select</a>
</li>
<li id='footnote-12'>
  12. <a href='https://andyatkinson.com/big-problems-big-in-clauses-postgresql-ruby-on-rails'>andyatkinson.com/big-problems-big-in-clauses-postgresql-ruby-on-rails</a>
</li>
<li id='footnote-13'>
  13. <a href='https://flexport.engineering/avoiding-activerecord-preparedstatementcacheexpired-errors-4499a4f961cf'>flexport.engineering/avoiding-activerecord-preparedstatementcacheexpired-errors-4499a4f961cf</a>
</li>
<li id='footnote-14'>
  14. <a href='https://depesz.com/2024/12/01/sql-best-practices-dont-compare-count-with-0'>depesz.com/2024/12/01/sql-best-practices-dont-compare-count-with-0</a>
</li>
<li id='footnote-15'>
  15. <a href='https://ibm.com/history/relational-database'>ibm.com/history/relational-database</a>
</li>
<li id='footnote-16'>
  16. <a href='https://andyatkinson.com/source-code-line-numbers-ruby-on-rails-marginalia-query-logs'>andyatkinson.com/source-code-line-numbers-ruby-on-rails-marginalia-query-logs</a>
</li>
<li id='footnote-17'>
  17. <a href='https://blog.appsignal.com/2018/06/19/activerecords-counter-cache.html'>blog.appsignal.com/2018/06/19/activerecords-counter-cache.html</a>
</li>
<li id='footnote-18'>
  18. <a href='https://github.com/simplecov-ruby/simplecov'>github.com/simplecov-ruby/simplecov</a>
</li>
<li id='footnote-19'>
  19. <a href='https://github.com/sbdchd/squawk'>github.com/sbdchd/squawk</a>
</li>
<li id='footnote-20'>
  20. <a href='https://github.com/ankane/strong_migrations'>github.com/ankane/strong_migrations</a>
</li>
<li id='footnote-21'>
  21. <a href='https://github.com/fatkodima/online_migrations?tab=readme-ov-file#comparison-to-strong_migrations'>github.com/fatkodima/online_migrations?tab=readme-ov-file#comparison-to-strong_migrations</a>
</li>
<li id='footnote-22'>
  22. <a href='https://andycroll.com/ruby/safely-remove-a-column-field-from-active-record/'>andycroll.com/ruby/safely-remove-a-column-field-from-active-record/</a>
</li>
<li id='footnote-23'>
  23. <a href='https://github.com/andyatkinson/pg_scripts/blob/main/find_missing_indexes.sql'>github.com/andyatkinson/pg_scripts/blob/main/find_missing_indexes.sql</a>
</li>
<li id='footnote-24'>
  24. <a href='https://github.com/andyatkinson/pg_scripts/pull/19'>github.com/andyatkinson/pg_scripts/pull/19</a>
</li>
<li id='footnote-25'>
  25. <a href='https://github.com/andyatkinson/pg_scripts/pull/18'>github.com/andyatkinson/pg_scripts/pull/18</a>
</li>
<li id='footnote-26'>
  26. <a href='https://github.com/andyatkinson/rideshare/pull/232'>github.com/andyatkinson/rideshare/pull/232</a>
</li>
<li id='footnote-27'>
  27. <a href='https://github.com/scenic-views/scenic'>github.com/scenic-views/scenic</a>
</li>
<li id='footnote-28'>
  28. <a href='https://andyatkinson.com/blog/2023/07/27/partitioning-growing-practice'>andyatkinson.com/blog/2023/07/27/partitioning-growing-practice</a>
</li>
<li id='footnote-29'>
  29. <a href='https://github.com/public-activity/public_activity'>github.com/public-activity/public_activity</a>
</li>
<li id='footnote-30'>
  30. <a href='https://github.com/paper-trail-gem/paper_trail'>github.com/paper-trail-gem/paper_trail</a>
</li>
<li id='footnote-31'>
  31. <a href='https://github.com/collectiveidea/audited'>github.com/collectiveidea/audited</a>
</li>
<li id='footnote-32'>
  32. <a href='https://github.com/ankane/ahoy'>github.com/ankane/ahoy</a>
</li>
<li id='footnote-33'>
  33. <a href='https://github.com/danmayer/coverband'>github.com/danmayer/coverband</a>
</li>
<li id='footnote-34'>
  34. <a href='https://andyatkinson.com/copy-swap-drop-postgres-table-shrink'>andyatkinson.com/copy-swap-drop-postgres-table-shrink</a>
</li>
<li id='footnote-35'>
  35. <a href='https://github.com/palkan/logidze'>github.com/palkan/logidze</a>
</li>
<li id='footnote-36'>
  36. <a href='https://maintainable.fm/episodes/andrew-atkinson-maintainable-databases'>maintainable.fm/episodes/andrew-atkinson-maintainable-databases</a>
</li>
<li id='footnote-37'>
  37. <a href='https://why-upgrade.depesz.com'>why-upgrade.depesz.com</a>
</li>
<li id='footnote-38'>
  38. <a href='https://andyatkinson.com/blog/2021/07/30/postgresql-index-maintenance'>andyatkinson.com/blog/2021/07/30/postgresql-index-maintenance</a>
</li>
<li id='footnote-39'>
  39. <a href='https://github.com/NikolayS/postgres_dba'>github.com/NikolayS/postgres_dba</a>
</li>
<li id='footnote-40'>
  40. <a href='https://github.com/andyatkinson/rideshare/pull/230'>github.com/andyatkinson/rideshare/pull/230</a>
</li>
<li id='footnote-41'>
  41. <a href='https://postgresql.org/docs/current/auto-explain.html'>postgresql.org/docs/current/auto-explain.html</a>
</li>
<li id='footnote-42'>
  42. <a href='https://postgres.ai/blog/20220106-explain-analyze-needs-buffers-to-improve-the-postgres-query-optimization-process'>postgres.ai/blog/20220106-explain-analyze-needs-buffers-to-improve-the-postgres-query-optimization-process</a>
</li>
<li id='footnote-43'>
  43. <a href='https://mysql.com/products/enterprise/em.html'>mysql.com/products/enterprise/em.html</a>
</li>
<li id='footnote-44'>
  44. <a href='https://sqlite.org/sqlanalyze.html'>sqlite.org/sqlanalyze.html</a>
</li>
<li id='footnote-45'>
  45. <a href='https://github.com/cerebris/jsonapi-resources'>github.com/cerebris/jsonapi-resources</a>
</li>
<li id='footnote-46'>
  46. <a href='https://github.com/rmosolgo/graphql-ruby'>github.com/rmosolgo/graphql-ruby</a>
</li>
<li id='footnote-47'>
  47. <a href='https://github.com/activeadmin/activeadmin'>github.com/activeadmin/activeadmin</a>
</li>
<li id='footnote-48'>
  48. <a href='https://andyatkinson.com/blog/2022/10/07/pgsqlphriday-2-truths-lie'>andyatkinson.com/blog/2022/10/07/pgsqlphriday-2-truths-lie</a>
</li>
<li id='footnote-49'>
  49. <a href='https://a.co/d/0Sk81B9'>a.co/d/0Sk81B9</a>
</li>
<li id='footnote-50'>
  50. <a href='https://dora.dev/quickcheck'>dora.dev/quickcheck</a>
</li>
<li id='footnote-51'>
  51. <a href='https://github.com/andyatkinson/presentations/tree/main/pass2024'>github.com/andyatkinson/presentations/tree/main/pass2024</a>
</li>
<li id='footnote-52'>
  52. <a href='https://en.wikipedia.org/wiki/Object–relational_impedance_mismatch'>en.wikipedia.org/wiki/Object–relational_impedance_mismatch</a>
</li>
<li id='footnote-53'>
  53. <a href='https://andyatkinson.com/constraint-driven-optimized-responsive-efficient-core-db-design'>andyatkinson.com/constraint-driven-optimized-responsive-efficient-core-db-design</a>
</li>
<li id='footnote-54'>
  54. <a href='https://ddnexus.github.io/pagy/docs/api/keyset/'>ddnexus.github.io/pagy/docs/api/keyset/</a>
</li>
<li id='footnote-55'>
  55. <a href='https://andyatkinson.com/blog/2023/08/17/postgresql-sfpug-table-partitioning-presentation'>andyatkinson.com/blog/2023/08/17/postgresql-sfpug-table-partitioning-presentation</a>
</li>
<li id='footnote-56'>
  56. <a href='https://wa.aws.amazon.com/wellarchitected/2020-07-02T19-33-23/wat.concept.mechanical-sympathy.en.html'>wa.aws.amazon.com/wellarchitected/2020-07-02T19-33-23/wat.concept.mechanical-sympathy.en.html</a>
</li>
<li id='footnote-57'>
  57. <a href='https://cybertec-postgresql.com/en/hot-updates-in-postgresql-for-better-performance'>cybertec-postgresql.com/en/hot-updates-in-postgresql-for-better-performance</a>
</li>
<li id='footnote-58'>
  58. <a href='https://bigbinary.com/blog/rails-6-adds-implicit_order_column'>bigbinary.com/blog/rails-6-adds-implicit_order_column</a>
</li>
<li id='footnote-59'>
  59. <a href='https://github.com/andyatkinson/rideshare/pull/233'>github.com/andyatkinson/rideshare/pull/233</a>
</li>
<li id='footnote-60'>
  60. <a href='https://atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow'>atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow</a>
</li>
<li id='footnote-61'>
  61. <a href='https://atlassian.com/continuous-delivery/continuous-integration/trunk-based-development'>atlassian.com/continuous-delivery/continuous-integration/trunk-based-development</a>
</li>
<li id='footnote-62'>
  62. <a href='https://github.com/andyatkinson/anchor_migrations'>github.com/andyatkinson/anchor_migrations</a>
</li>
<li id='footnote-63'>
  63. <a href='https://cybertec-postgresql.com/en/products/pg_squeeze/'>cybertec-postgresql.com/en/products/pg_squeeze/</a>
</li>
</ul></div>
</section>

