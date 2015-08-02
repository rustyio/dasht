Dasht.map_plot_address = function(map, markers, geocoder, address) {
    geocoder.geocode({ "address": address }, function(results, status) {
        // Don't plot if the lookup failed.
        if (status != google.maps.GeocoderStatus.OK) return;

        // Don't plot a location we've already plotted.
        var location = results[0].geometry.location;

        Dasht.map_plot_location(map, markers, location);
    });
}

Dasht.map_plot_ip = function(map, markers, ip) {
    // http://freegeoip.net/json/
    jQuery.ajax({
        url: 'http://104.236.251.84/json/' + ip,
        type: 'POST',
        dataType: 'jsonp',
        success: function(response) {
            var location = new google.maps.LatLng(response.latitude, response.longitude);
            Dasht.map_plot_location(map, markers, location);
        },
        error: function (xhr, ajaxOptions, thrownError) {
            alert("Failed!");
        }
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
                { hue: "#ffffff" },
                { saturation: -100 },
                { lightness: 20 },
                { gamma: 0.5 }
            ]
        },
        {
            featureType: "water",
            stylers: [
                { hue: "#333333" },
                { saturation: -100 },
                { lightness: -60 },
                { gamma: 0.43 }
            ]
        }
    ];

    var mapOptions = {
        zoom: 4,
        center: new google.maps.LatLng(39.8282, -98.5795),
        styles: styles,
        disableDefaultUI: true
    };

    var map_el = $(el).find(".map").get()[0];
    var num_entries = options["n"] || 10;
    var map = new google.maps.Map(map_el, mapOptions);
    window.markers = [];
    var geocoder = new google.maps.Geocoder();
    var ip_regex = /\d+\.\d+\.\d+\.\d+/;

    // Set the map height to be tile height minus title height.
    $(el).find(".map").height($(el).height() - $(el).find(".title").outerHeight());

    // Update with pins.
    $(el).on("update", function(event, value) {
        value = value[0];
        if (_.isEqual(old_value, value)) return;

        // Plot each marker.
        _.each(value, function(item, index) {
            if (item.search(ip_regex) >= 0) {
                Dasht.map_plot_ip(map, markers, item);
            } else {
                Dasht.map_plot_address(map, markers, geocoder, item);
            }
        });

        old_value = value;
    });
}
