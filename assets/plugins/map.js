
function map_init(el, options) {
    var old_value = undefined;
    var num_entries = options["n"] || 10;
    var mapOptions = {
        zoom: 4,
        center: new google.maps.LatLng(39.8282, -98.5795)
    };
    var map_el = $(el).find(".map").get()[0];
    var map = new google.maps.Map(map_el, mapOptions);
    window.markers = [];
    var geocoder = new google.maps.Geocoder();

    // Set the map height to be tile height minus title height.
    $(el).find(".map").height($(el).height() - $(el).find(".title").outerHeight());

    // Update with pins.
    $(el).on("update", function(event, value) {
        if (_.isEqual(old_value, value)) return;

        // Plot each marker.
        _.each(value, function(address, index) {
            geocoder.geocode({ 'address': address }, function(results, status) {
                // Don't plot if the lookup failed.
                if (status != google.maps.GeocoderStatus.OK) return;

                // Don't plot a location we've already plotted.
                var location = results[0].geometry.location;
                var location_exists = _.any(markers, function(value) {
                    return _.isEqual(value.position, location);
                });
                if (location_exists) return;

                // Drop a pin.
                var marker = new google.maps.Marker({
                    map: map,
                    animation: google.maps.Animation.DROP,
                    position: results[0].geometry.location
                });

                // Track the pin.
                markers.push(marker);

                // Trim old pins.
                while (markers.length > num_entries) {
                    var marker = markers.shift();
                    marker.setMap(null);
                }
            });
        });

        old_value = value;
    });
}
