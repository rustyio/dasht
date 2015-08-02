// Initialize some vars.
Dasht = new function(){
    this.timers          = {};
    this.fontsize_small  = 12;
    this.fontsize_medium = 30;
    this.fontsize_large  = 80;
}();

Dasht.add_tile = function(options) {
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
    if (Dasht[options.type + "_init"] != undefined) {
        Dasht[options.type + "_init"](el, options);
    }
}

Dasht.init = function() {
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
            Dasht.schedule_timer(metric, resolution, refresh);
        }
    });


    if ($(document).width() > 640) {
        $('#container').masonry({
            itemSelector: '.tile'
        });
    }

    $(".js-expand").each(function(index, el) {
        var parent = $(el).parent();
        $(el).outerHeight(parent.height() - parent.find(".title").outerHeight(true));
        var marginsize = parseInt($(el).css("margin-left")) + parseInt($(el).css("margin-right"));
        $(el).outerWidth(parent.width() - marginsize);
    });

    setInterval(Dasht.scale_fontsize, 1000);
}

Dasht._scale_fontsize = function(selector, size, min_size, max_size) {
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

Dasht.scale_fontsize = function() {

    Dasht.fontsize_small  = Dasht._scale_fontsize(".fontsize-small", Dasht.fontsize_small, 10, 20);
    Dasht.fontsize_medium = Dasht._scale_fontsize(".fontsize-medium", Dasht.fontsize_medium, 25, 45);
    Dasht.fontsize_large  = Dasht._scale_fontsize(".fontsize-large", Dasht.fontsize_large, 55, 90);
}

Dasht.schedule_timer = function(metric, resolution, refresh) {
    var key = [metric,resolution];

    // Clear the old interval.
    if (Dasht.timers[key]) {
        clearTimeout(Dasht.timers[key]);
    }

    // Create the new interval.
    Dasht.timers[key] = setTimeout(function() {
        Dasht.update_metric(metric, resolution, refresh);
    }, refresh * 1000);
}

Dasht.update_metric = function(metric, resolution, refresh) {
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
            Dasht.schedule_timer(metric, resolution, refresh);
        }
    });
}
