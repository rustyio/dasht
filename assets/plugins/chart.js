Dasht.chart_init = function(el, options) {
    var chart = $(el).find(".chart");
    var chart_el = chart.get()[0];
    var old_value = 0;

    Dasht.fill_tile(chart);

    // Create some empty values.
    var labels = [];
    var data = [];
    for (var i = 0; i < options.history; i++) {
        labels.push("");
        data.push(0);
    }

    // Create the chart.
    var chart_data = {
        labels: labels,
        datasets: [
            {
                fillColor: "rgba(255,255,255,0.2)",
                strokeColor: "rgba(255,255,255,0.4)",
                data: data
            }
        ]
    };

    var chart_options = {
        showScale: false,
        showTooltips: false,
        pointDot : false
    }

    var ctx = $(".chart").get(0).getContext("2d");
    var chart = new Chart(ctx).Line(chart_data, chart_options);

    // Handle value updates.
    setTimeout(function() {
        Dasht.update_metric(options, function(value) {
            console.log(value);
            console.log(options);
            if (_.isEqual(old_value, value)) return;

            // Update chart values.
            for (var i = 0; i < options.history; i++) {
                chart.datasets[0].points[i].value = value[i];
            }
            chart.update();

            old_value = value;
        });
    }, 1000);
}
