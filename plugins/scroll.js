function scroll_init(el, options) {
    var metric = $(el).find(".metric");
    var old_value = undefined;
    $(el).on('update', function(event, value) {
        if (old_value == value) return;
        old_value = value;
        metric.animate({ opacity: 0.5 }, 0, function() {
            metric.html(value.join("<br />"));
            metric.animate({ opacity: 1.0 }, 400);
        });
    });
}
