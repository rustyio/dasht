var dasht_timers = {};

function add_tile(options) {
    // Generate the html.
    var html = $("#" + options.type + "-template").html();
    var el = $.parseHTML($.trim(Mustache.render(html, options)))[0];

    // Initialize the element.
    window[options.type + "_init"](el, options);

    // Update the page.
    $("#container").append(el);
}

function dasht_init() {
    $("[data-metric]").each(function(index, el) {
        var metric     = $(el).data("metric");
        var resolution = $(el).data("resolution");
        var refresh    = $(el).data("refresh");

        // Schedule the timer, but only if it refreshes more quickly than an
        // existing timer.
        var refresh_rates = {};
        var key = [metric,resolution];
        if (refresh_rates[key] == undefined || refresh < refresh_rates[key]) {
            // Set the new rate.
            refresh_rates[key] = refresh;
            dasht_schedule_timer(metric, resolution, refresh);
        }
    });
}

function dasht_schedule_timer(metric, resolution, refresh) {
    var key = [metric,resolution];

    console.log(["timer", metric, resolution, refresh]);

    // Clear the old interval.
    if (dasht_timers[key]) {
        clearTimeout(dasht_timers[key]);
    }

    // Create the new interval.
    dasht_timers[key] = setTimeout(function() {
        dasht_update_metric(metric, resolution, refresh);
    }, refresh * 1000);
}

function dasht_update_metric(metric, resolution, refresh) {
    var url = "/data/" + metric + "/" + resolution;
    $.get(url).done(function(value) {
        // Update the UI.
        var selector = '[data-metric="' + metric + '"][data-resolution="' + resolution + '"]';
        $(selector).each(function(index, el) {
            var old_value = $(el).data("value");
            if (old_value != value) {
                $(el).html(value);
                $(el).data("value", value);
                $(el).trigger('changed', old_value, value);
            }
        });

        // Schedule the new timer.
        if (refresh) {
            dasht_schedule_timer(metric, resolution, refresh);
        }
    });
}

function value_init(el, options) {
}
