---
layout: post
title: "Prioritizing Work that Matters"
tags: [Productivity]
date: 2021-10-15
comments: true
---

In the [StaffEng](https://staffeng.com/) book, there is a section called [Work on What Matters](https://staffeng.com/guides/work-on-what-matters).

This section has good descriptions of how to classify certain types of work a software engineer does, and how to prioritize for higher impact.

What I liked in this section was the emphasis on thinking about work in dimensions of "effort", "impact", and "visibility."


#### On "Avoiding Snacking"

"Snacking" is work that is relatively easy and low-impact. Some things that came to mind in Ruby on Rails web development for me were:

* Updating a minor or patch version of a gem dependency
* Updating a patch version of Rails
* Adopting a new well documented API

These things have some value, but are also easy and probably low in business impact, and low in visibility. As the guide says, snack sized work is good to fill in gaps or could be good to hand off to someone with less experience performing these tasks in general.

These can also be useful to build some "momentum" or inertia as a new contributor, with a new technology, or on a new team.

But just like in life outside programming, a healthy diet does not consist solely of snacks.


#### On "Stop Preening"

"Preening" is lower impact work like snacking but instead of low visibility, it's high-visibility work.

This made me think of taking on a pet project for a boss. It might be highly visible work because the boss has asked for it, but it's also lower in impact to the business since it's a pet project.

Preening projects might still be useful to help build trust (the "right hand man" archetype) and reputation between colleagues, trust is important, but the project may not benefit the individual's skill growth or development either.

The author encourages the reader to strike a balance between work that is valued at the org, and personal growth.


#### On "Chasing Ghosts" 👻

*Ghosts* are low-impact, high-effort projects that aren't quite done. A new person may be brought in to try and solve these problems! Equipped with their new energy, maybe they can crack the nut.

> Taking the time to understand the status quo before shifting it will always repay diligence with results.

These projects might also be doomed to fail. It may be a difficult conversation to have with a boss, but align on the business value, and discuss whether the [sunk cost fallacy](https://en.wikipedia.org/wiki/Sunk_cost) is in effect.


#### What should you work on? Existential issues.


What is an existential issue? Well, at a startup, running out of money is an existential crisis. An extinction level event? Work on those things?

Another example listed reminded me of some recent experience. We'd scaled our primary database vertically to the largest instance class and there was concern our workload would even exceed that.

Since there was no way to purchase more scale, working on application scalability went from nice-to-have, to need-to-have. It became easier to "sell" the engineering effort here. We performed a variety of changes, including separating the most high write rate metrics tables to their own database.


#### Work where this is room and attention

The guide suggests working where there is both room to work (things to be done, in other words "problems that are not fully solved", or under-staffed), and "attention to the work".

This makes sense to me. Adding more staff to a project where there isn't clear work to be done is unproductive. Adding resources to projects that have been ignored for a long time will probably result in their effort being ignored.

Some questions the book suggests:

* What might become priorities in the future where you can work in advance of that?
* Areas that are "ok" now, but could be "great" with your contributions(!) 📈
* Be mindful of working in a company area that is not well supported. The area may be interesting personally, but invisible work is often not rewarded at all or rewarded poorly.


#### More Ideas

These are copied from the book, with my own quick summaries added.

* *Foster growth*. Growing the team around you is appreciated and valuable.
* "Edit" - improve something that was "good" that could be "great".
* "Finish things" (be a "closer" (like in baseball))
* Work on "What only you can do". Delegate tasks that do not represent personal growth opportunities. Bring unique skills to the team for individual work. Share knowledge to level-up the team.


#### Wrap Up

The [StaffEng](https://staffeng.com/) book is very energizing to me, I highly recommend it!
