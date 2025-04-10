---
layout: post
title: "Building SMS and Voice Features for Web Applications"
date: 2015-02-12
comments: true
tags: [Programming, Ruby]
---

At [OrderUp](http://orderup.com) we rely on voice calls and SMS messages to communicate quickly with customers and team members. SMS messaging means that we don't need to know the specific platform or capabilities (iOS or Android) of the recipient device. It Just Works &#0153; (most of the time).

[Twilio](https://www.twilio.com/) (and the [twilio-ruby gem](https://github.com/twilio/twilio-ruby)) are great tools. Twilio has a rich API and tons of documentation to build SMS and voice services for a variety of use cases. [Tropo](http://tropo.com/) and [Nexmo](http://nexmo.com/) offer similar services to Twilio.

## SMS Verification for New Customers
Like many startups we want to acquire new, high-quality customers. To help do that we offer a one-time credit for new customers. The tricky part is trying to maintain a low-friction sign-up process while simultaneously reducing or preventing fraudulent usage of the credit.

Currently we're using a verified phone number as a unique identifier for a customer. This also allows us to establish SMS communication with the customer.

To build SMS verification into the app we used Twilio. Here are some of the basics:

## Capture the customer phone number and send a SMS
Make a form for the user to post their phone number. Either store it (or log it) or use it directly in the Twilio API call to create a SMS message. We use Heroku and use ENV variables to store our Twilio credentials. Sending a SMS message is as easy as making an API post to Twilio. Check the latest [ruby gem](https://github.com/twilio/twilio-ruby) documentation.

```ruby
twilio = Twilio::REST::Client.new(ENV['TWILIO_SID'], ENV['TWILIO_TOKEN'])
message = twilio.account.messages.create(
  :from => from,
  :to =>   phone,
  :body => message
)
```

You may want to enqueue the API post so that it can be executed from a background job. This makes it easier to re-run the code later following a bug fix.

## Create a callback to receive replies
Create a callback in the web app. For our Ruby on Rails application we put this stuff in a controller. You might want another action you can post at to re-send the confirmation SMS.

The controller action receives a HTTP post from Twilio and uses the params to determine what to do next. In our case, we look up the phone number and make sure we have it and that it is associated with a customer.

```ruby
class FrontEnd::SmsVerificationsController < FrontEnd::BaseController

  def receive_message
  # ...
  end

  def resend_sms
  # ...
  end

end
```

## Process SMS message replies
* Create a Twilio phone number and configure it with the callback URL (get the fully-qualified URL via Rails routes). Adding a phone number on Twilio can be done manually or via the API. Separate callbacks can be configured for voice and SMS.
* In development, use [ngrok](https://ngrok.com/) or a similar tool to expose your local server to the Internet. It may be easier to use separate phone numbers (they are priced as low as $1/month) for different environments. Otherwise you need to remember to change the callback URLs when the code goes in to production.

Now SMS messages can be sent to the customer, and replies will come in via the webhook. Twilio offers logs of inbound and outbound message activity for a number so check there if something isn't working correctly. In the case of SMS number verification, we send out a unique code and then make sure that the customer replies with the same unique code.

## Phone number masking
Another voice and SMS feature we've built is phone number masking. With this feature, neither the driver's phone number nor the customer's phone number are exposed to each other. Twilio has a couple of options for how to implement this. In a follow-up blog post I'll go into detail about the two implementations we've had in production, including the pros and cons of each.

In order to share a Twilio phone number, we built a reservation system where a particular number is reserved to connect two parties for a period of time. During the reservation period, for either voice calls or SMS messages, the recipient of a message sees the Twilio number in their caller ID.

By running the calls through Twilio, we can log the calls and SMS messages, provide automated announcements (e.g. "Connecting you with the customer, please wait..."), and link calls and messages to related data in our database for reporting.

## Adding and releasing phone numbers via the Twilio API
Twilio phone numbers can be queried and reserved using the API. This is the preferred method when there are many phone numbers to add and release. We keep track of the Twilio numbers we've reserved in our database so we can update the callback URLs or release the number later.

We're also able to register local numbers for each of our markets due to the large number of phone numbers available through Twilio. Since we operate in many markets, we felt having phone numbers that were local to the market would increase the chances that a customer would reply (compared with a generic 800 number).

## Adding and releasing Twilio numbers via the API
To release a number, look up the `SID` and send an HTTP DELETE request via the API. We have taken advantage of easily adding and releasing numbers to dynamically increase the Twilio numbers we are using based on demand. Pretty cool!

We made a phone number tool we can use to add and release numbers. A simplified version is displayed below. Using this tool, we can check from a periodic job whether we need to buy more numbers, based on how many are currently being used. This way we only have as many as we need for each market.

```ruby
class TwilioPhoneNumberTool
  attr_accessor :client, :market_id, :quantity, :sms_endpoint, :voice_endpoint

  def initialize(options)
    self.market_id = options[:market_id]
    self.quantity = options.fetch(:quantity, 1)
    self.client = Twilio::REST::Client.new(ENV['TWILIO_SID'], ENV['TWILIO_TOKEN'])
    self.sms_endpoint = ''# ...
    self.voice_endpoint = '' #...
  end

  def market
    @market ||= Market.find_by_id(market_id)
  end

  def search_criteria
    market_center = # ... get an object with a lat and lng
    {
      near_lat_long: "#{market_center.lat},#{market_center.lng}",
      distance: 50, # miles
      region: market.state,
      sms_enabled: true,
      voice_enabled: true,
      mms_enabled: true
    }
  end

  def add_numbers
    numbers = client.account.available_phone_numbers.get('US').local.list(search_criteria)
    numbers.first(quantity).each do |twilio_number|
      params = {
        phone_number: twilio_number.phone_number,
        sms_url: orderup_sms_endpoint,
        voice_url: orderup_voice_endpoint
      }
      begin
        client.account.incoming_phone_numbers.create(params)
        # ...save the twilio number in your DB so you can edit or release it later
      rescue Exception => e
        Rails.logger.error "Failed #{e.message}" # ...
      end
    end
  end
end
```

## Closing Thoughts
API providers like Twilio and Nexmo make it relatively easy to build SMS and voice features for your web app. SMS and voice may be a much faster way to push out information for real-time operations-oriented businesses.

* SMS and API voice calls help the operations side of the business communicate quickly with customers. Consider whether voice calls and SMS may deliver a better customer experience.
* SMS can be used as an additional way to verify a person. Two-factor authentication is a common example. Replying to SMS can also be defeated by people willing to put in some effort, so consider the pros and cons.
* Phone masking helps secure your customer and team information by limiting exposure. A reservation system helps you share a limited set of resources.

Leave a comment or hit me up on twitter with questions or suggestions. Thanks!
