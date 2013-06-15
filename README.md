Team Dashboard Tips & Tutorial
===

I've been setting up a dashboard for my team to display metrics. After looking around at the various options (and having an abortive stab at writing a framework myself) I found and OSS version called
[Dashing written by Shopify](http://shopify.github.io/dashing/) that suited the needs.

There's a [nice example on YouTube](http://www.youtube.com/watch?v=TbGbm1cE6M0) which I think gives a better feel than the built in samples.

I thought I'd put a few hints and tips after what I've learnt.

Why do you want a team dashboard? A dashboard can provide an overview of the team's status, and highlight actions that need to be taken. The ones we've got include:

Actionable tiles:
* Build status. Which builds (of the 41 builds) that are broken, and who the CI thinks broken them. This goes red if builds are broken and indicates who needs to fix the build.
* Failing tests. Again, which tests are failing and who the CI thinks broke them. Since the test's package can indicate which feature needs fixing, this also indicates who might want to take a look.
* Recorded time. Who has not recorded their time in the timesheet system.</span></li>
* New tickets. Untriaged tickets in the bug tracking system, that need to be triaged.
* Overdue code reviews.
Information tiles:
* Recent commits. This shows what we're working on.
* Beer clock: On Fridays, how many hours to free beer.
* Assigned tickets. Tickets we're working on.
* Test coverage.

What do you notice here? More tiles are actionable rather than informative, and therefore more useful. The current weather or the company stock prices do not feature. It's not an executive dashboard, it is a team dashboard.

What else do you notice? Each metrics comes from a different system. Build information might be from Jenkins or Bamboo, tickets from JIRA or RT, and the timesheet information might be [from a spreadsheet](http://www.youtube.com/watch?v=cJMRKB3RU_s). This means you'll need to write a script to periodically extract the data and post it to the dashboard - there's a good chance you won't find a built it one that fits your exact requirements. Assume you'll need to write some of you own, but do not fear - this is almost trivially easy!

Creating a Widget
---
This tutorial will create a dashboard with a single widget:

<img src="https://raw.github.com/alexec/dashing-example/master/screenshot.png"/>

To install Dashing you need Ruby 1.9 (I'd recommend [RVM](https://rvm.io)), and then execute:

    gem install dashing
    dashing new example-dashboard
    cd example-dashboard
    bundle install && dashing start

This creates a set of samples you can look at by navigating to [http://localhost:3030/sample](http://localhost:3030/sample).

Lets create a widget that shows informatain about failing builds. It'll be closely related to [a Sonar Gist](https://gist.github.com/EHadoux/5196209), and follows a common set-of steps:

* Get same data from a URL, possbily having to authenticate.
* Parse that data (if it is HTML we can [use Mechianize](http://mechanize.rubyforge.org)).
* Loop though the data to find the interesting information.
* Filter that information, e.g. based on status.
* Post that information to one of more widgets.

<pre><code>
    SCHEDULER.every '15m', :first_in => 0 do |job|
        builds=config[:builds].map{|repo|
            status=JSON(get("https://api.travis-ci.org/repositories/#{config[:user]}//#{repo}/builds.json"))[0]['result']?'ok':'failing'
            {:repo => repo, :status => status}
        }
        failing_builds=builds.find_all{|build| build[:status]!='ok'}
            send_event('travis_builds', {
            :items => builds.map{|build| {:label => "#{build[:repo]} #{build[:status]}"}},
            :moreinfo => "#{failing_builds.length}/#{builds.length} failing",
            :status => (failing_builds.length>0?'warning':'ok')
        })
    end
</code></pre>

To create the widget I've copied the widgets/list to widgets/travis_builds and added this to the code to change the colour of the widget based on status:

       onData: (data) ->
         if data.status
           # clear existing "status-*" classes
           $(@get('node')).attr 'class', (i,c) ->
             c.replace /\bstatus-\S+/g, ''
           # add new class
           $(@get('node')).addClass "status-#{data.status}"

Installing as a On a PC
---
You'll want to run this on a Linux computer with a monitor mounted in a suitable place.

I've [written a script to start this as service on Linux](https://raw.github.com/alexec/dashing-example/master/dashboard.sh). You'll need to add a cd to change to the correct directory.

If you want to be eco-friendly you can turn the screen on and off at suitable times using xset, put this in your crontab:

    # turn on at 9am weekdays
    0 9 1-5 * * xset dpms force on
    # turn off at 6/7/8pm everyday (just in case it get knocked on by accident)
    0 18,19,20 * * * xset dpms force off

Now you have a few options for the actual display.

A simple and fully featured, but insecure, option would be to use a browser fullscreen and disable the screensaver.

A more secure, but quite hacky option would be to [set-up xscreensaver to rotate thought](http://forums.pcbsd.org/showthread.php?t=5878) a directory of [screenshots taken by phantomjs](https://github.com/ariya/phantomjs/wiki/Screen-Capture).

I'd love to hear from anyone with a better compromise!

References
---
Code for this post can be [found on Github](https://github.com/alexec/dashing-example). Another widgets can be [found amongst the additional widgets page](https://github.com/Shopify/dashing/wiki/Additional-Widgets). [The guide](http://shopify.github.io/dashing/) gives an example of creating your own widget.

