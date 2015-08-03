Dasht.metric_update = function(el, value) {
    $(el).css("opacity", 0.8);
    $(el).html(value.toLocaleString());
    $(el).animate({ "opacity": 1.0 });
}

Dasht.metric_init = function(el, options) {
    // Initialize.
    var metric = $(el).find(".metric");
    var metric_el = metric.get()[0];
    var old_value = 0;

    // Set the metric height to be tile height minus title height.
    Dasht.fill_tile(metric);
    metric.css("line-height", metric.innerHeight() + "px");

    // Update values.
    setTimeout(function() {
        Dasht.get_value(options, function(value) {
            value = value[0];
            if (_.isEqual(old_value, value)) return;
            Dasht.metric_update(metric, value);
            old_value = value;
        });
    }, 1000);
}
