function value_init(el, options) {
    var metric = $(el).find(".metric");
    var metric_el = metric.get()[0];
    var old_value = 0;
    $(el).on('update', function(event, value) {
        if (_.isEqual(old_value, value)) return;
        $(metric).html(value);
        // new CountUp(metric_el, old_value, value, 0, 1.0, { useEasing: false }).start();
        old_value = value;
    });
}
