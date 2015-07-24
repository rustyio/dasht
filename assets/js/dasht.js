function value_init(el) {

}

function add_tile(options) {
    console.log(options);
    // Generate the html.
    var html = $("#" + options.type + "-template").html();
    var el = $.parseHTML($.trim(Mustache.render(html, options)))[0];

    // Initialize the element.
    window[options.type + "_init"](el);

    // Update the page.
    $("#container").append(el);
}

function dasht_init() {
}

$(function() {
});
