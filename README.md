# Dasht

Dasht is a framework for building beautiful ops/developer dashboards. It's especially good for displaying high-level application stats in real-time on a wall-mounted monitor. Dasht is a Ruby / Rack application open-sourced under the MIT license.

Dasht works best with a Twelve-Factor (Heroku style) app. Specifically, your app should treat [logs as streams](http://12factor.net/logs). Dasht gathers data from log streams using a regular expression, aggregates the data in a very simple in-memory time series database, then publishes the data (or some form of the data) to tiles on a dashboard. A typical Dasht dashboard takes just a few minutes of coding and is usually less than 100 lines of Ruby.

[Screen Shot]

# Installation

Getting started with Dasht is easy:

```sh
    # Install the gem.
    gem install dasht

    # Create a dashboard.
    vi my_dashboard.rb

    # Run the dashboard.
    ruby my_dashboard.rb
```

Here is a simple dashboard for Heroku apps. Look in **examples** folder for more options.

```ruby
require 'dasht'

application = ARGV[0]

dasht do |d|
  # Consume Heroku logs.
  d.start "heroku logs --tail --app #{application}"

  # Track some metrics.
  d.count :lines, /.+/

  d.count :bytes, /.+/ do |match|
    match[0].length
  end

  d.append :visitors, /for (\d+\.\d+\.\d+\.\d+) at/ do |matches|
    matches[1]
  end

  counter = 0
  d.interval :counter do
    sleep 1
    counter += 1
  end

  # Publish a board.
  d.board do |b|
    b.metric :counter,  :title => "Counter"
    b.metric :lines,    :title => "Number of Lines"
    b.metric :bytes,    :title => "Number of Bytes"
    b.chart  :bytes,    :title => "Chart of Bytes", :history => 10
    b.map    :visitors, :title => "Visitors", :width => 12, :height => 9
  end
end
```

# Documentation

## Injesting Data

Dasht gets data by running a command (or tailing a log file) and listening to the output. A single Dasht instance can listen to multiple sources. If the command ends for some reason, it is automatically restarted.

Some examples:

```ruby
# Start a command, process the output.
d.start("heroku logs --tail --app my_application")

# Tail a file, process the new data.
d.tail("/path/to/my_application.log")
```

### Measures

Dasht tries to apply each new log line against a series of user-defined regular expressions. When a regular expression matches, the measure is updated based on the measure type..

There are a number of pre-defined measure types:

+ `gauge` - Set a measure.
+ `count` - Increment a measure by some amount. (defaults to 1 if no block is provided).
+ `min` - Update the minimum value.
+ `max` - Update the maximum value.
+ `append` - Keep a list of values of a measure (useful for non-numeric data.)

Unless otherwise noted, all measure definitions require a block. The block should a regular expression match into a numeric value. Measures should be kept as simple and compact as possible to keep memory requirements low.

Some examples:

```ruby
# Track the total number of log lines processed.
d.count :lines, /.+/

# Track the total size of the logs, in bytes.
d.count :bytes, /.+/ do |match|
  match[0].length
end

# Track the maximum response time.
d.max :max_response, /Completed 200 OK in (\d+)ms/ do |match|
  match[1].to_i
end

# Track visitor IP addresses.
d.append :visitors, /Started GET .* for (\d+\.\d+\.\d+\.\d+) at/ do |matches|
  matches[1]
end
```

You can also define your own measure types with the `event` command. The `op` parameter is any Array instance method. Money patching can come in handy if the built-in Array methods don't do what you need.

```ruby
# Format is d.event(metric, regex, op, &block). The definition below
# would set the measure to the first occurance of some measure value
# for a given timeframe.
d.event(:my_metric, /some-regex/, :first) do |match|
  match[1].to_i
end
```

Dasht has one more measure type, an interval type meant for querying external data sources on a regular schedule.

```ruby
# Query external data. Acts as a gauge, and sets the measure to the
# return value of the block.
d.interval :my_metric do
  sleep 5
  hash = JSON.parse(Net::HTTP.get("http://website/some/api.json"))
  hash["value"]
end
```

### Boards

### Tiles

### Custom Tiles

Dasht is also extensible. It ships with three types of plugins ('metric', 'chart, and 'map') that are suitable for most uses. New plugins are fairly easy to write. A simple plugin takes around 30 lines of Javascript.


# TODO

+ DONE - Fix responsiveness.
+ DONE - Fix exception logging.
+ DONE - Automatically reduce font for value fields.
+ DONE - Count up with more resource efficiency.
+ DONE - Rename value to metric.
+ DONE - Convert plugins to Dasht namespace.
+ DONE - Custom map css.
+ DONE - Update map to look up by things other than email address.
+ DONE - Change layout to 12 * 12 grid.
+ DONE - Convert map to do IP lookups on client side.
+ DONE - Support for reading multiple groups of data.
+ DONE - Load data right away, don't wait.
+ DONE - Cache IP lookups.
+ DONE - Create a CSS class that causes an element to fill available height.
+ DONE - Chart type tile.
+ DONE - Board level settings for resolution and refresh.
+ DONE - Board level settings for element size.
+ DONE - Interval types.
+ DONE - Simplify metric update.

+ Change dashboard color.
+ Load plugins from local file.
+ Remove points from the map.
+ Clear out old stats to free memory.
+ Fix up scrolling tile.
+ "Delta" tile. (Up / down X percent.)
+ Documentation
+ Blog post
