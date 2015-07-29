function scroll_init(el, options) {
    var num_entries = options["n"] || 10;
    var metric = $(el).find(".metric");
    var old_value = undefined;
    $(el).on('update', function(event, value) {
        value = value.slice(-1 * num_entries);
        if (old_value != undefined && (old_value.toString() == value.toString())) return;
        old_value = value;
        metric.animate({ opacity: 0.8 }, 0, function() {
            metric.html(value.join("<br />"));
            metric.animate({ opacity: 1.0 }, 400);
        });
    });
}
