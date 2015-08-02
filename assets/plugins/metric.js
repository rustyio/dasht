Dasht.metric_count_up = function(el, start_value, end_value, speed, n) {
    var i = 0;
    var step = Math.floor((end_value - start_value) / n);
    var timeout = setInterval(function() {
        if (i < (n - 1)) {
            start_value += step;
            i += 1;
            $(el).html(start_value.toLocaleString());
        } else {
            $(el).html(end_value.toLocaleString());
            clearTimeout(timeout);
        }
    }, (speed / (n - 1)));
}

Dasht.metric_init = function(el, options) {
    var metric = $(el).find(".metric");
    var metric_el = metric.get()[0];
    var old_value = 0;

    // Set the metric height to be tile height minus title height.
    Dasht.fill_tile(metric);
    metric.css("line-height", metric.innerHeight() + "px");

    // Handle value updates.
    $(el).on('update', function(event, value) {
        value = value[0];
        if (_.isEqual(old_value, value)) return;
        Dasht.metric_count_up(metric, old_value, value, options.refresh * 1000, options.refresh * 10);
        old_value = value;
    });
}
