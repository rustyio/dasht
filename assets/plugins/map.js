Dasht.map_plot_address = function(map, markers, geocoder, address) {
    geocoder.geocode({ "address": address }, function(results, status) {
        // Don't plot if the lookup failed.
        if (status != google.maps.GeocoderStatus.OK) return;

        // Don't plot a location we've already plotted.
        var location = results[0].geometry.location;
        Dasht.map_plot_location(map, markers, location);
    });
}

Dasht.map_plot_location = function(map, markers, location) {
    var location_exists = _.any(markers, function(value) {
        return _.isEqual(value.position, location);
    });
    if (location_exists) return;

    // Drop a pin.
    var marker = new google.maps.Marker({
        map: map,
        animation: google.maps.Animation.DROP,
        position: location
    });

    // Track the pin.
    markers.push(marker);

    // // Trim old pins.
    // while (markers.length > num_entries) {
    //     var marker = markers.shift();
    //     marker.setMap(null);
    // }
}

Dasht.map_init = function(el, options) {
    var old_value = undefined;
    var styles = [
        {
            stylers: [
                { hue: "#334455" },
                { saturation: -80 },
                { lightness: -10 },
                { gamma: 1 }
            ]
        }
    ];

    var mapOptions = {
        zoom: 4,
        center: new google.maps.LatLng(39.8282, -98.5795),
        styles: styles
    };

    var map_el = $(el).find(".map").get()[0];
    var num_entries = options["n"] || 10;
    var map = new google.maps.Map(map_el, mapOptions);
    window.markers = [];
    var geocoder = new google.maps.Geocoder();

    // Set the map height to be tile height minus title height.
    $(el).find(".map").height($(el).height() - $(el).find(".title").outerHeight());

    // Update with pins.
    $(el).on("update", function(event, value) {
        value = value[0];
        if (_.isEqual(old_value, value)) return;

        // Plot each marker.
        _.each(value, function(item, index) {
            if (typeof(item) == "string") {
                Dasht.map_plot_address(map, markers, geocoder, item);
            } else {
                var location = new google.maps.LatLng(item.latitude, item.longitude)
                Dasht.map_plot_location(map, markers, location);
            }
        });

        old_value = value;
    });
}
