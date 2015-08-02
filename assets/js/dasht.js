// Initialize some vars.
Dasht = new function(){
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
    if ($(document).width() > 640) {
        $('#container').masonry({
            itemSelector: '.tile'
        });
    }

    setInterval(Dasht.scale_fontsize, 1000);
}

Dasht.fill_tile = function(el) {
    var parent = $(el).parent();
    $(el).outerHeight(parent.height() - parent.find(".title").outerHeight(true));
    var marginsize = parseInt($(el).css("margin-left")) + parseInt($(el).css("margin-right"));
    $(el).outerWidth(parent.width() - marginsize);
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


Dasht.update_metric = function(options, callback) {
    var metric     = options["metric"];
    var resolution = options["resolution"] || 60;
    var history    = options["history"]    || 1;
    var refresh    = options["refresh"]    || 5;
    var url = "/data/" + options.metric + "/" + options.resolution + "/" + history;

    $.get(url).done(function(value) {
        // Update the UI.
        callback(value);

        setTimeout(function() {
            Dasht.update_metric(options, callback);
        }, refresh * 1000);
    });
}
