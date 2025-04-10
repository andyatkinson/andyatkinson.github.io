---
layout: post
title: Email Service Providers for Rails
date: 2010-09-02
comments: true
tags: [Ruby, Rails]
---

Sending email (transactional and marketing) is part of most every web application. At work our project is nearing its first public release and we are talking about emails the application may be sending. The emails we know the application will be sending now are transactional emails like the "welcome" email for new users and password resets, however we are also expect our marketing team to send release announcements. We want to format the emails with HTML and CSS. 

## Email service providers
Using a service provider that integrates well with Rails and still allows the company to manage emails outside of the application would be very useful. Delivering high volumes of email can be technically challenging, and outsourcing that to a service would work well for our small development team. 

Most of these services provide email tracking and reporting as well, which we would not get from a standard Rails mailer setup. The reporting helps us understand deliverability, opens, and clicks.

Most of these services test their HTML and CSS templates in email clients like Microsoft Outloook, to ensure they render properly. This saves our company time since we don’t have to check rendering.

The services we looked at: Postmark, PostageApp, Mad Mimi, and SendGrid

I will also provide a 1 year cost estimate using the following data:
50 users signing up per month, each receiving 1 welcome email, 1 password change email, 1 monthly feature announcement. Totals:

- Monthly: 150
- Yearly: 1800

## [Postmark](http://postmarkapp.com/)
- No monthly fees or setup costs
- Advertised as replacing SMTP, a server you can send HTTP requests at with email details, messages are encoded as JSON data. Attachments need to be encoded as a base-64 string.
- Rails gem available
- REST API for delivery stats, bounces, and more
- Appears to be “single user”.
- No “message template editor” to design emails within the app.

$1.50/1000 emails

$.0015/email

**Projected yearly cost** for 1800 emails: @ $.0015 = **$2.70** (very low cost)

Conclusion for our project: very low cost, does not offer email template design services.

## [PostageApp](http://postageapp.com/)
- Rails gem available
- Emails are encoded as JSON and sent as HTTP Post requests to PostageApp. 
- Message Template user interface, build HTML/CSS emails with a preview. Templates can be stored.
- 5 projects, 2 user accounts, 50KB message size (this size includes attachments)

(monthly cost is greater than per email cost)
**Projected yearly cost**: **$9**/month x 12 = $72/year (typical price among competitors)

Conclusion: seems great for a application. The message design tool requires working with HTML and CSS.

## [Mad Mimi](http://madmimi.com/)
- More marketing and newsletter oriented. Newsletter and recipient list management features. 
- Ruby gem available, with methods to send email and get tracking/status information as well.
- No sign-up fees, monthly prices and free account
- Building HTML emails with drag and drop tools. Can generate preview link of email (seems very useful to share this with team members not using Mad Mimi itself, prior to sending email)
- Additional “add-ons” available for free and additional fees depending on the add-on, available for email campaigns. Free add-on that seems very useful: multiple accounts.
- Advertised as placing a high-value on customer service and seems to be thoughtfully designed, to make things simple and reduce clutter.

Additional note: the drag and drop editor interface seems very easy to use for someone that does not want to hand-code HTML and CSS.

Price: segmented primarily on number of email recipients:

$8/month for 500 emails ($0.016/email), $10/month for 1000 emails ($0.01/email)

Mailer API is extra: $10/month

**Projected yearly cost** for 1800 emails ($8 plan plus Mailer API): **$216**  (higher priced, but also offers more marketing features)

Conclusion: great for an application. Higher priced, but drag-and-drop message design interface seems very user friendly

## [SendGrid](http://sendgrid.com/)
I originally heard about SendGrid through Heroku, since SendGrid is offered as an add-on to Heroku instances.
- Track email clicks, opens, unsubscribes and more
- Email services: parse incoming email
- Only service to require mailing address and telephone number for sign-up form.
- Has a newsletter template editor, not as user-friendly as the one in Mad Mimi
- Unique “Filters” available such as email to phone-call (can receive a voice translation of an email).
- “open tracking” available, which uses an invisible image in the email to track when it is opened.

Price: $9.95/month for 10,000 emails ($0.000995/email)

**Projected yearly cost** for 1800 emails: **$119.40**

Conclusion: Offers lots of features. May have a feature you really want that the others don’t have.

## Conclusion
For our company I think Mad Mimi will be the most valuable service. It has the capability through the Mailer API and variable substitution with curly braces ([documented here](http://garbageburrito.com/blog/entry/235921/outsource-your-email-notifications-with-madmimis-mailer-api)) to send customized emails from the application. It also has an interface to build promotions without writing any HTML or CSS (building HTML/CSS emails is also possible).

## Mad Mimi
Recipients specified through the Mailer API are automatically visible in the Mad Mimi UI. There are API methods to add contacts, so we should be able to keep our user database in sync with any other email recipients added from outside the application. Mad Mimi also offers a permalink to share a promotion without having to log-in, which I think would be useful over IM and email to make sure the promotion has the variables specified in it that the application will be supplying, or for general copy and image review.

## API
The API is wrapped in the [official madmimi Ruby gem](http://github.com/madmimi/madmimi-gem) that makes it very easy to work with. Here is some example code to send an email. Note that the Mailer API add-on requires a credit card to try, but is free if canceled within the first 5 days (I used this to test).

I created a test promotion called `Promo test 1` and in one of the text blocks specified a variable like this: `Hello {name}!`. Creating an email and supplying the value for `{name}` looks like this. I didn't find the curly braces documented on the Mad Mimi site. Another feature called [personalization_tags](http://help.madmimi.com/personalization-tag/) are similar but don’t work when supplying variable values as below, use the curly brace syntax.

```rb
mimi = MadMimi.new(APP_CONFIG[:mad_mimi_email], APP_CONFIG[:mad_mimi_api_key])
options = { 'promotion_name' => 'Promo test 1', 
            'recipients' => 'email@gmail.com', 
            'from' => 'App <do-not-reply@app.com>', 
            'subject' => 'Test Subject' }
yaml_body = {'name' => 'Bob Jones' }
mimi.send_mail(options, yaml_body)
```

I hope this comparison of several email services with some estimated prices was useful for you. Do you use another email service provider?
