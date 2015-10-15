Dasht.map_geocoder_cache = {}

Dasht.map_plot_address = function(map, markers, geocoder, address) {
    // Maybe pull the location from cache.
    var location;
    if (location = Dasht.map_geocoder_cache[address]) {
        Dasht.map_plot_location(map, markers, address, location);
        return;
    }

    geocoder.geocode({ "address": address }, function(results, status) {
        // Don't plot if the lookup failed.
        if (status != google.maps.GeocoderStatus.OK) return;
        var location = results[0].geometry.location;
        Dasht.map_geocoder_cache[address] = location;
        Dasht.map_plot_location(map, markers, address, location);
    });
}

Dasht.map_plot_ip = function(map, markers, ip) {
    // Maybe pull the location from cache.
    var location;
    if (location = Dasht.map_geocoder_cache[ip]) {
        Dasht.map_plot_location(map, markers, ip, location);
        return;
    }

    jQuery.ajax({
        url: 'http://freegeoip.net/json/' + ip,
        type: 'POST',
        dataType: 'jsonp',
        success: function(response) {
            var location = new google.maps.LatLng(response.latitude, response.longitude);
            Dasht.map_geocoder_cache[ip] = location;
            Dasht.map_plot_location(map, markers, ip, location);
        },
        error: function (xhr, ajaxOptions, thrownError) {
            alert("Failed!");
        }
    });
}

Dasht.map_plot_coordinates = function(map, markers, coordinates) {
    // Maybe pull the location from cache.
    var location;
    if (location = Dasht.map_geocoder_cache[coordinates]) {
        Dasht.map_plot_location(map, markers, coordinates, location);
        return;
    }

    var coordinate_regex = /\[(-?\d+\.\d+),\s*(-?\d+\.\d+)\]/;
    var matches = coordinates.match(coordinate_regex);
    var lng = parseFloat(matches[1]);
    var lat = parseFloat(matches[2]);
    var location = new google.maps.LatLng(lat, lng);
    Dasht.map_geocoder_cache[coordinates] = location;
    Dasht.map_plot_location(map, markers, coordinates, location);
}

Dasht.map_plot_location = function(map, markers, item, location) {
    var location_exists = _.any(_.values(markers), function(marker) {
        return _.isEqual(marker.position, location);
    });
    if (location_exists) return;

    // Drop a pin.
    var marker = new google.maps.Marker({
        map: map,
        animation: google.maps.Animation.DROP,
        position: location
    });

    // Keep track of markers.
    markers[item] = marker;
}

Dasht.map_init = function(el, options) {
    // Initialize.
    var old_data = undefined;
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
                { hue: "#ffffff" },
                { saturation: 80 },
                { lightness: 100 },
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
    var markers = {};
    var geocoder = new google.maps.Geocoder();
    var ip_regex = /\d+\.\d+\.\d+\.\d+/;
    var coordinate_regex = /\[(-?\d+\.\d+),\s*(-?\d+\.\d+)\]/;

    Dasht.fill_tile($(el).find(".map"));

    // Update values.
    setTimeout(function() {
        Dasht.get_value(options, function(new_data) {
            new_data = new_data[0];
            if (_.isEqual(old_data, new_data)) return;

            // Remove old markers.
            var old_markers = _.difference(_.keys(markers), new_data);
            _.each(old_markers, function(address) {
                markers[address].setMap(null);
                delete markers[address];
            });

            // Plot each marker.
            _.each(new_data, function(item, index) {
                if (item.search(ip_regex) >= 0) {
                    Dasht.map_plot_ip(map, markers, item);
                } else if (item.search(coordinate_regex) >= 0) {
                    Dasht.map_plot_coordinates(map, markers, item);
                } else {
                    Dasht.map_plot_address(map, markers, geocoder, item);
                }
            });

            old_data = new_data;
        });
    }, 1000);
}
