function scroll_init(el, options) {
    var old_value = undefined;
    var num_entries = options["n"] || 10;
    var metric = $(el).find(".metric");
    $(el).on('update', function(event, value) {
        value = value.slice(-1 * num_entries);
        if (_.isEqual(old_value, value)) return;
        metric.animate({ opacity: 0.8 }, 0, function() {
            metric.html(value.join("<br />"));
            metric.animate({ opacity: 1.0 }, 400);
        });
        old_value = value;
    });
}
