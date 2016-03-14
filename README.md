# trbial

tribial creates digests of current events using the Wikipedia Current Events portal. You can use this tool to create your own news digests. Or, say, create a weekly digest to study up for the current events trivia round at your local pub.

## Requirements

This tool depends on a few gems to make the magic happen. Here's a quick command that you can run to install the necessary ones:

    $ gem install mediawiki_api activesupport redcarpet mail
    
This tool has been tested against Ruby 2.3.0, but should work with most stable 2.x versions.

trbial is not a gem itself, so please clone the repository to use it:

    $ git clone https://github.com/jontec/trbial.git

## Usage

Once the prerequisites are satisfied, running trbial is quite, well, trivial:

```ruby
require_relative 'trbial'

t = Trbial.new # Defaults to a 7 day digest (inclusive of today)
t.retrieve_events
t.export_events
t.send_events # Sends the digest e-mail. See configuration details below
````

## Configuring the Mail Client

The mail client uses configuration settings in the `mail_options.yml` file. A sample is provided as `mail_options.yml.sample`, tailormade for working with a personal GMail address.

Get started right away by renaming the sample, entering your user name, and updating the message details. You can choose to enter your password, or as is the default, let trbial prompt you on the command line when it's ready to send your digest.