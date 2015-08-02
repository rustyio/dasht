Dasht.chart_init = function(el, options) {
    var chart = $(el).find(".chart");
    var chart_el = chart.get()[0];
    var old_value = 0;

    var data = {
        labels: ["", "", "", "", "", "", ""],
        datasets: [
            {
                fillColor: "rgba(255,255,255,0.2)",
                strokeColor: "rgba(255,255,255,0.4)",
                data: [65, 59, 80, 81, 56, 55, 40]
            }
        ]
    };

    var options = {
        animation: false,
        showScale: false,
        showTooltips: false,
        pointDot : false
    }

    setTimeout(function() {
        var ctx = $(".chart").get(0).getContext("2d");
        var myLineChart = new Chart(ctx).Line(data, options);
    }, 1000);
}
