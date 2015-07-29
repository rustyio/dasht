function value_init(el, options) {
    var metric = $(el).find(".metric");
    var old_value = 0;
    $(el).on('update', function(event, value) {
        if (old_value == value) return;
        new CountUp(metric.get()[0], old_value, value, 0, 1.0, { useEasing: false }).start();
        old_value = value;
        // metric.animate({ opacity: 0.7 }, 0, function() {
        //     metric.html(value.toLocaleString());
        //     metric.animate({ opacity: 1.0 }, 400);
        // });
    });
}
