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

function _resize_helper(selector, size, min_size, max_size) {
    var elements = $(selector);

    var any_too_small = function() {
        return _.any(elements, function(el) {
            return (($(el)[0].scrollWidth <= $(el).innerWidth()) ||
                    ($(el)[0].scrollHeight <= $(el).innerHeight()));
        });
    }

    var any_too_big = function() {
        return _.any(elements, function(el) {
            return (($(el)[0].scrollWidth > $(el).innerWidth()) ||
                    ($(el)[0].scrollHeight > $(el).innerHeight()));
        });
    }

    while (size <= max_size && any_too_small()) {
        size = size + 1;
        $(elements).css("font-size", size + "px");
    }

    while (size >= min_size && any_too_big()) {
        size = size - 1;
        $(elements).css("font-size", size + "px");
    }

    return size;
}

window.fontsize_small = 12;
window.fontsize_medium = 30;
window.fontsize_large = 80;

function dasht_resize_text() {
    window.fontsize_small = _resize_helper(".fontsize-small", window.fontsize_small, 10, 20);
    window.fontsize_medium = _resize_helper(".fontsize-medium", window.fontsize_medium, 25, 45);
    window.fontsize_large = _resize_helper(".fontsize-large", window.fontsize_large, 55, 90);
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
