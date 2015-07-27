var dasht_timers = {};

function add_tile(options) {
    // Generate the html.
    var template_key = "#" + options.type + "-template";
    var html = $(template_key).html();
    if (html == undefined) {
        alert("Template not found: " + template_key);
    }
    var el = $.parseHTML($.trim(Mustache.render(html, options)))[0];

    // Initialize the element.
    if (window[options.type + "_init"] != undefined) {
        window[options.type + "_init"](el, options);
    }

    // Update the page.
    $("#container").append(el);
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
            itemSelector: '.tile',
            isFitWidth: true,
            gutter: 30,
            columnWidth: 0
        });
    }

    $(".graph").width($(".tile").width());
    $(".graph").height($(".tile").height() - 40);

    var graph = new Rickshaw.Graph( {
        element: document.querySelector(".graph"),
        series: [{
            color: '#000000',
            min: 0,
            max: 1000,
            data: [
                { x: 0, y: 40 },
                { x: 1, y: 49 },
                { x: 2, y: 38 },
                { x: 3, y: 30 },
                { x: 4, y: 32 } ]
        }]
    });
    graph.render();
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
    $.get(url).done(function(value) {
        // Update the UI.
        var selector = '[data-metric="' + metric + '"][data-resolution="' + resolution + '"]';
        $(selector).each(function(index, el) {
            var old_value = $(el).data("value");
            if (old_value != value) {
                $(el).html(value);
                $(el).data("value", value);
                $(el).trigger('changed', [old_value, value]);
            }
        });

        // Schedule the new timer.
        if (refresh) {
            dasht_schedule_timer(metric, resolution, refresh);
        }
    });
}

function value_init(el, options) {
    var metric = $(el).find(".metric");
    $(el).on('changed', function(event, old_value, new_value) {
        metric.animate({ opacity: 0.5 }, 0, function() {
            metric.animate({ opacity: 1.0 }, 400);
        });

        var percent = 100.0 * (new_value - options.min) / (options.max - options.min);
        percent = Math.min(Math.max(0, percent), 100);
        $(el).find(".progress div").animate({ width: percent + "%" });
    });
}
