var dasht_timers = {};

function add_tile(options) {
    // Generate the html.
    var template_key = "#" + options.type + "-template";
    var html = $(template_key).last().html();
    if (html == undefined) {
        alert("Template not found: " + template_key);
    }
    var el = $.parseHTML($.trim(Mustache.render(html, options)))[0];

    // Update the page.
    $("#container").append(el);

    // Initialize the element.
    if (window[options.type + "_init"] != undefined) {
        window[options.type + "_init"](el, options);
    }
}

function dasht_init() {
    $("[data-metric]").each(function(index, el) {
        var metric     = $(el).attr("data-metric");
        var resolution = $(el).attr("data-resolution");
        var refresh    = $(el).attr("data-refresh");

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


    if ($(document).width() > 640) {
        $('#container').masonry({
            itemSelector: '.tile'
        });
    }
}

function dasht_resize_text() {
    var min_size = 30;
    var max_size = 200;
    $(".resize-text").each(function(index, el) {
        $(el).css("overflow", "scroll");

        // Grow it.
        console.log($(el)[0].scrollWidth, $(el).innerWidth());
        console.log($(el)[0].scrollHeight, $(el).innerHeight());
        while (($(el)[0].scrollWidth <= $(el).innerWidth()) &&
               ($(el)[0].scrollHeight <= $(el).innerHeight())) {
            var fontSize = parseInt($(el).css("font-size"));
            if (fontSize >= max_size) break;
            $(el).css("font-size", (fontSize + 1) + "px");
        }

        // Shrink it.
        while (($(el)[0].scrollWidth > $(el).innerWidth()) ||
               ($(el)[0].scrollHeight > $(el).innerHeight())) {
            var fontSize = parseInt($(el).css("font-size"));
            if (fontSize <= min_size) break;
            $(el).css("font-size", (fontSize - 1) + "px");
        }
    });
}

function dasht_schedule_timer(metric, resolution, refresh) {
    var key = [metric,resolution];

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
    var selector = '[data-metric="' + metric + '"][data-resolution="' + resolution + '"]';
    var key = [metric, resolution];

    $.get(url).done(function(value) {
        // Update the UI.
        $(selector).each(function(index, el) {
            $(el).trigger('update', [value]);
        });

        // Schedule the new timer.
        if (refresh) {
            dasht_schedule_timer(metric, resolution, refresh);
        }
    });
}
