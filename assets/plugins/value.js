function value_init(el, options) {
    var metric = $(el).find(".metric");
    var metric_el = metric.get()[0];
    var old_value = 0;

    // Set the map height to be tile height minus title height.
    metric.height($(el).height() - $(el).find(".title").outerHeight());
    metric.css("line-height", metric.height() + "px");
    metric.css("vertical-align", "center");
    $(el).on('update', function(event, value) {
        if (_.isEqual(old_value, value)) return;
        $(metric).html(value);
        // new CountUp(metric_el, old_value, value, 0, 1.0, { useEasing: false }).start();
        old_value = value;
    });
}
