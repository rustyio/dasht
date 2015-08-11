// Initialize some vars.
Dasht = new function(){
    this.fontsize_small  = 12;
    this.fontsize_medium = 30;
    this.fontsize_large  = 80;
    this.pending_requests = [];
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
    Dasht.scale_fontsize_loop();
    Dasht.process_pending_requests_loop();
    Dasht.watchdog_loop();
}

Dasht.fill_tile = function(el, do_width, do_height) {
    var parent = $(el).parent();
    if (do_width || do_width == undefined) {
    var marginsize = parseInt($(el).css("margin-left")) + parseInt($(el).css("margin-right"));
        $(el).outerWidth(parent.width() - marginsize);
    }
    if (do_height || do_height == undefined) {
        var marginsize = parseInt($(el).css("margin-top")) + parseInt($(el).css("margin-bottom"));
        $(el).outerHeight(parent.height() - marginsize);
    }
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

Dasht.scale_fontsize_loop = function() {
    Dasht.fontsize_small  = Dasht._scale_fontsize(".fontsize-small", Dasht.fontsize_small, 10, 20);
    Dasht.fontsize_medium = Dasht._scale_fontsize(".fontsize-medium", Dasht.fontsize_medium, 25, 45);
    Dasht.fontsize_large  = Dasht._scale_fontsize(".fontsize-large", Dasht.fontsize_large, 55, 90);
    setTimeout(Dasht.scale_fontsize_loop, 1000);
}

Dasht.get_value = function(options, callback) {
    // Add to the list of pending requests.
    Dasht.pending_requests.push({
        metric:     options["metric"],
        resolution: options["resolution"] || 60,
        periods:    options["periods"]    || 1,
        refresh:    options["refresh"]    || 5,
        callback:   callback
    });
}

Dasht.process_pending_requests_loop = function() {
    // Nothing to do. Return.
    if (Dasht.pending_requests.length == 0) {
        setTimeout(Dasht.process_pending_requests_loop, 500);
        return;
    }

    // Split pending_requests into query data and callback data.
    var queries = [];
    var callbacks = [];
    _.each(Dasht.pending_requests, function(o) {
        callbacks.push(o.callback);
        delete o.callback;
        queries.push(o);
    });
    Dasht.pending_requests = [];

    var successFN = function(responses) {
        Dasht.loaded_data = true;
        $("body").removeClass("waiting");

        // Process the responses.
        _.each(responses, function(response, i) {
            var query    = queries[i];
            var callback = callbacks[i];
            callback(response);
            setTimeout(function() {
                Dasht.get_value(query, callback);
            }, query.refresh * 1000);
        });

        // Loop.
        setTimeout(Dasht.process_pending_requests_loop, 500);
    }

    // Perform the request.
    $("body").addClass("waiting");
    $.ajax({
        url: "/data",
        type: 'post',
        dataType: 'json',
        data: JSON.stringify(queries),
        success: successFN
    });
}


Dasht.loaded_data = true;
Dasht.watchdog_loop = function() {
    // The page could get stuck for a variety of reasons. This is the
    // last resort. Run every 2 minutes. If we haven't loaded new data
    // in that time, then reload the page.
    if (Dasht.loaded_data == true) {
        Dasht.loaded_data = false;
        setTimeout(Dasht.watchdog_loop, 2 * 60 * 1000);
    } else {
        document.location.reload();
    }
}
