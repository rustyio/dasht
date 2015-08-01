Dasht.metric_count_up = function(el, start_value, end_value, n = 10) {
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
    }, 1000 / n);
}

Dasht.metric_init = function(el, options) {
    var metric = $(el).find(".metric");
    var metric_el = metric.get()[0];
    var old_value = 0;

    // Set the map height to be tile height minus title height.
    metric.height($(el).height() - $(el).find(".title").outerHeight());
    metric.css("line-height", metric.height() + "px");
    metric.css("vertical-align", "center");
    $(el).on('update', function(event, value) {
        value = value[0];
        if (_.isEqual(old_value, value)) return;
        Dasht.metric_count_up(metric, old_value, value);
        old_value = value;
    });
}
