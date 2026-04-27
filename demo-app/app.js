(function () {

var svgwidth = Math.min(document.documentElement.clientWidth, 500);
var svgheight = 0.7 * Math.min(document.documentElement.clientWidth, 500);

var strokescale = function(s) {
    var pointscale = d3.scaleQuantize()
        .domain([0, svgwidth])
        .range(Array.from(Array(200).keys()));

    for (var i = s.length - 1; i >= 0; i--) {
        s[i] = {x:pointscale(s[i]['x']), y:pointscale(svgheight - s[i]['y'])};
    }
    return s;
};

var printstroke = function(s) {
    dump = d3.select("#info")
    dump.style("display", "none");

    dump = d3.select("#dump")
    dump.style("display", "block");
    dump.selectAll("span").remove();
    dump.append("span").attr("class", "dump").text(s);
};

var stroke = [];
var tablet = d3.select("#tablet");

var canvas = tablet.append("svg")
    .attr("width", svgwidth)
    .attr("height", svgheight)
    .on("mousedown", mousedown)
    .on("mouseup", mouseup)
    .on("touchstart", touchstart)
    .on("touchend", touchend)

function mousedown() {
    var m = d3.mouse(this);
    var p = {x:Math.trunc(m[0]), y:Math.trunc(m[1])};

    // clear canvas when stroke begins
    canvas.selectAll("*").remove();

    // draw first stroke point on canvas
    canvas.append("circle").attr("cx", p.x).attr("cy", p.y).attr("r", 5);
    stroke.push(p);

    canvas.on("mousemove", mousemove);
}

function mousemove() {
    var m = d3.mouse(this);
    var p = {x:Math.trunc(m[0]), y:Math.trunc(m[1])};

    // draw next stroke point on canvas
    canvas.append("circle").attr("cx", p.x).attr("cy", p.y).attr("r", 2);
    stroke.push(p);
}

function mouseup() {
    // dump recorded stroke
    output = JSON.stringify(strokescale(stroke), null, 2);
    printstroke(output);

    // restart for new stroke
    stroke = [];
    canvas.on("mousemove", null);
}

function touchstart() {
    var m = d3.touches(this)[0];
    var p = {x:Math.trunc(m[0]), y:Math.trunc(m[1])};

    // clear canvas when stroke begins
    canvas.selectAll("*").remove();

    // draw first stroke point on canvas
    canvas.append("circle").attr("cx", p.x).attr("cy", p.y);
    stroke.push(p);

    canvas.on("touchmove", touchmove);
}

function touchmove() {
    var m = d3.touches(this)[0];
    var p = {x:Math.trunc(m[0]), y:Math.trunc(m[1])};

    // draw next stroke point on canvas
    canvas.append("circle").attr("cx", p.x).attr("cy", p.y);
    stroke.push(p);
}

function touchend() {
    // dump recorded stroke
    output = JSON.stringify(strokescale(stroke), null, 2);
    printstroke(output);

    // restart for new stroke
    stroke = [];
    canvas.on("touchmove", null);
}

})();