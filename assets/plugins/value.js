Dasht.value_update = function(el, value) {
    $(el).css("opacity", 0.7);
    $(el).html(value.toLocaleString());
    $(el).animate({ "opacity": 1.0 });
}

Dasht.value_init = function(el, options) {
    // Initialize.
    var value = $(el).find(".value");
    var value_el = value.get()[0];
    var old_data = undefined;

    // Set the value height to be tile height minus title height.
    Dasht.fill_tile($(el).find(".title"), true, false);
    Dasht.fill_tile(value);

    // Update values.
    setTimeout(function() {
        Dasht.get_value(options, function(new_data) {
            new_data = new_data[0];
            if (_.isEqual(old_data, new_data)) return;
            Dasht.value_update(value, new_data);
            old_data = new_data;
        });
    }, 1000);
}
