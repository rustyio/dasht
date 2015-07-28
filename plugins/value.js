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
