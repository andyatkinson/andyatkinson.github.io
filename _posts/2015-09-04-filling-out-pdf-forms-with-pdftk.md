---
layout: post
title: "Filling out PDF forms with PDFtk"
date: 2015-09-04 13:00
comments: true
tags: [Programming, Productivity, Ruby]
---

At work we collect IRS W9 forms from our independent contractor partners each year. This year we wanted to automate the process of collecting the information, by allowing the contractors to supply their information through their existing app.

## Problem
We needed to have our contractor partners complete a IRS W9 form inside the app that they are already using. The app is used on a variety of iOS and Android devices, and has limited screen real estate. It is a hybrid app with a native wrapper but mostly composed of HTML/CSS/JS, so we wanted a web-friendly solution.

We evaluated some third-party solutions like HelloSign for this process. These typically involve including an `iframe` on the page, so it is more difficult to style and control that UI experience. These solutions do allow you to put together templated documents and collect input though, just with a bit less control over the presentation.

## Solution
Ultimately we decided to roll a solution ourselves because we had more control over the UI/UX. We were able to use some great open source software to make this happen.

The solution involved a regular web form, a PDF with fillable fields with specific identifiers, `pdftk` and the `pdf-forms` [^gem] gem. *Pre-Filling PDF Form Templates in Ruby-on-Rails with PDFtk* [^article] has code samples for Ruby classes to make nicer interfaces to working with the command line tool. I put together a demo app and the structure there is similar to what is described in that blog post.

## Storing and serving the document
We use Amazon S3 for storing files. For these documents it was a good fit, especially since we were able to enable bucket-level encryption. The app uses HTTPS/SSL so traffic is encrypted in flight. Additionally, sensitive attributes we collect (PII) are encrypted at the database field-level as well.

The process is as follows. The user fills out a regular web form. Afterwards, `pdftk` is used to generate a PDF form, then the form is uploaded to S3. We store the key to the S3 object so that we can present the file in the web UI (using a signed/credentialed request).

The overall experience is pretty smooth.

## Setting up PDFtk in development (OS X)
* Install PDFtk server tools. You will get the `pdftk` executable when this is complete.
* Add the `pdf-forms` gem to your Gemfile.
* I used LibreOffice [^libre] (open source, free) to create the fillable fields and export a PDF. Adobe Acrobat is probably even easier to use, but it wasn't available.

## Setting up PDFtk in production (Heroku)
Derek Barber has an excellent article [^art] on *Using PDFtk on Heroku* with step-by-step installation instructions. I also tried a Heroku Buildpack but I recommend following the steps in Derek's article instead. The instructions involve committing a binary that works on Heroku, to your repository, and then updating your Heroku paths to find it.

## Demo App
Using this information, I set up a demo app that shows the PDF form generation in action. The form had fields added to it using LibreOffice. For the demo, there is a web form that captures a name, storing it in the database, and a button can be used to generate a PDF form. The PDF form is generated using PDFtk, and uploaded to an S3 bucket. A link is created to the object in S3.

- [Form Filler Demo](https://form-filler-demo.herokuapp.com/)
- [Form Filler Demo source code](https://github.com/andyatkinson/form-filler-demo)

## Extras
* `pdftk` has a useful option `dump_data_fields` that shows the fillable fields and values. You can run this before and after editing the PDF, and confirm the values that are set.
* In LibreOffice, on a fillable field, right-click the field and choose "Control" to view or customize the name for the field.

Give the demo app a shot. Thanks to the authors of the blog posts mentioned here. Let me know if you have questions or suggestions!

[^gem]: [pdf-forms gem](http://github.com/jkraemer/pdf-forms)
[^article]: [Pre-Filling PDF Form Templates in Ruby-on-Rails with PDFtk](http://adamalbrecht.com/2014/01/31/pre-filling-pdf-form-templates-in-ruby-on-rails-with-pdftk/)
[^art]: [Using PDFtk With Rails on Heroku](http://derekbarber.ca/blog/2014/11/20/using-pdftk-with-rails-on-heroku/)
[^libre]: [LibreOffice Fresh](https://www.libreoffice.org/download/libreoffice-fresh/)
