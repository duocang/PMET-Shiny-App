//Code comes from https://bl.ocks.org/mbostock/1389927

//Wrap the entire D3 script in this function. It is looking for a jsondata message sent from Shinys server session object.
Shiny.addCustomMessageHandler('jsondata', function (pmet) {

  //Lets nuke out any thing on our page with the id of "d3Graph". This will prevent 
  //our app from making a new graph each time a parameter is changed
  // d3.select("#d3").remove();
  // d3.select("#d3Graph").remove();
  d3.selectAll("svg").remove();

  // svg.selectAll(".rect1").remove();
  // svg.selectAll("#xAxis").remove();
  // svg.selectAll("#yAxis").remove();

  //The message comes from shiny, it is the json payload from our session





  // var ids = Object.keys(pmet.data);

  // // set the dimensions and margins of the graph
  // var margin = { top: 5, right: 30, bottom: 150, left: 80 },
  //   width = 420 - margin.left - margin.right,
  //   height = 470 - margin.top - margin.bottom;

  // var valMax = 0;
  // var valMin = 0;

  // for (var id of ids) {
  //   var dataFiltered = pmet.data[id].filter(function (dat) { return dat.gene_num > 0 })

  //   valMax = Math.max(valMax, Math.max(...dataFiltered.map(o => o.p_adj)))
  //   valMin = Math.min(valMin, Math.min(...dataFiltered.map(o => o.p_adj)))
  // }


  // for (var id of ids) {
  //   // append the svg object to the body of the page
  //   var mainsvg = d3.select("#placeholder_" + id)
  //     .append("svg")
  //     .attr("id", "mainsvg-" + id)
  //     .attr("width", width + margin.left + margin.right)
  //     .attr("height", height + margin.top + margin.bottom)
  //     .append("g")
  //     .attr("transform",
  //       "translate(" + margin.left + "," + margin.top + ")");

  //   var svgHeatmap = drawHeatmap(data = pmet.data[id],
  //     svg = mainsvg,
  //     svgID = "#placeholder_" + id,
  //     heatmapID = "rect" + id,
  //     valMax = valMax,
  //     valMin = valMin,
  //     clusters = pmet.clusters)
  // }

  console.log(pmet)
  if (pmet.method == "All") {
    var ids = Object.keys(pmet.data);

    // set the dimensions and margins of the graph
    var margin = { top: 5, right: 30, bottom: 150, left: 80 },
      width = 500 - margin.left - margin.right,
      height = 540 - margin.top - margin.bottom;

    var valMax = 0;
    var valMin = 0;

    for (var id of ids) {
      var dataFiltered = pmet.data[id].filter(function (dat) { return dat.gene_num > 0 })

      valMax = Math.max(valMax, Math.max(...dataFiltered.map(o => o.p_adj)))
      valMin = Math.min(valMin, Math.min(...dataFiltered.map(o => o.p_adj)))
    }

    for (var id of ids) {
      // append the svg object to the body of the page
      var mainsvg = d3.select("#placeholder")
        .append("svg")
        .attr("id", "mainsvg-" + id)
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
        .append("g")
        .attr("transform",
          "translate(" + margin.left + "," + margin.top + ")");

      var svgHeatmap = drawHeatmap(data = pmet.data[id],
        svg = mainsvg,
        svgID = "#placeholder",
        heatmapID = "rect" + id,
        valMax = valMax,
        valMin = valMin,
        clusters = pmet.clusters)
    }
  } else if (pmet.method == "Aggregation") {
    var ids = Object.keys(pmet.data);

    // set the dimensions and margins of the graph
    var margin = { top: 10, right: 50, bottom: 120, left: 150 },
      width = 500 - margin.left - margin.right,
      height = 400 - margin.top - margin.bottom;

    var valMax = 0;
    var valMin = 0;

    for (var id1 of pmet.clusters) {
      for (var id2 of pmet.clusters) {
        var id = id1 + "_" + id2
        var dataFiltered = pmet.data[id].filter(function (dat) { return dat.gene_num > 0 })

        valMax = Math.max(valMax, Math.max(...dataFiltered.map(o => o.p_adj)))
        valMin = Math.min(valMin, Math.min(...dataFiltered.map(o => o.p_adj)))
      }


      for (var id2 of pmet.clusters) {
        var id = id1 + "_" + id2

        // append the svg object to the body of the page
        var mainsvg = d3.select("#placeholder")
          .append("svg")
          .attr("id", "mainsvg-" + id)
          .attr("width", width + margin.left + margin.right)
          .attr("height", height + margin.top + margin.bottom)
          .append("g")
          .attr("transform",
            "translate(" + margin.left + "," + margin.top + ")");

        var svgHeatmap = drawHeatmap(data = pmet.data[id],
          svg = mainsvg,
          svgID = "#placeholder",
          heatmapID = "rect" + id,
          valMax = valMax,
          valMin = valMin,
          clusters = pmet.clusters,
          cluster_motif = id1)
      }
    }
  } else {

    var dataFiltered = pmet.data.filter(function (dat) {
      return dat.gene_num > 0
    })

    var valMax = Math.max(...dataFiltered.map(o => o.p_adj))
    var valMin = Math.min(...dataFiltered.map(o => o.p_adj))

    // set the dimensions and margins of the graph
    var margin = { top: 10, right: 60, bottom: 170, left: 120 },
      width = 900 - margin.left - margin.right,
      height = 920 - margin.top - margin.bottom;

    // append the svg object to the body of the page
    var mainsvg = d3.select("#placeholder")
      .append("svg")
      .attr("id", "mainsvg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
      .append("g")
      .attr("transform",
        "translate(" + margin.left + "," + margin.top + ")");

    var svgHeatmap = drawHeatmap(data = pmet.data,
      svg = mainsvg,
      svgID = "#placeholder",
      heatmapID = "rect",
      valMax = valMax,
      valMin = valMin,
      clusters = pmet.clusters)

  }


  function drawHeatmap(data, svg, svgID = null, heatmapID = null, valMax = 0, valMin = 0, clusters = null, cluster_motif = null) {

    // Three function that change the tooltip when user hover / move / leave a cell
    var mouseover = function (d) {
      if (d.gene_num > 0) {
        tooltip
          .style("opacity", 1)
        d3.select(this)
          .style("stroke", "black")
          .style("opacity", 1)
      }
    }

    var mousemove = function (d) {
      if (d.gene_num > 0) {
        tooltip
          .html("<b>motif x</b>: " + d.motif1 + "<br>" +
            "<b>motif y</b>: " + d.motif2 + "<br>" +
            "<b>cluster</b>  :" + d.cluster + "<br>" +
            "<b>-log10(p.adj)</b>:   " + d.p_adj + "<br>" +
            "<b># genes</b>: " + d.gene_num + "<br>" //+  "<b>genes</b>:<br>" + "&nbsp;&nbsp;&nbsp;&nbsp;" + d.genes 
          )
          // .style("left", (d3.mouse(this)[0] + 60) + "px")
          // .style("top" , (d3.mouse(this)[1] + 120 ) + "px")
          .style("left", (d3.event.pageX - 600) + "px")
          .style("top", (d3.event.pageY - 250) + "px")
      }
    }

    var mouseleave = function (d) {
      if (d.gene_num > 0) {
        tooltip
          .style("opacity", 0)
        d3.select(this)
          .style("stroke", "none")
          .style("opacity", 0.8)
      }
    }

    var mouseclick = function (d) {
      if (d.gene_num > 0) {
        d3.select(svgID)
          .html(
            '<div ><button>&times;</button> <h2>Automatic Pop-Up</h2> <p> Gene: </p> </div>'
          )
          .style("width", "400px")
      }
    }

    function wrap(textElements, width) {
      textElements.each(function () {
        d3.select(this).html(function (text) {
          var words = text.split(/\s+/),
            word,
            lines = [],
            currentLine = '',
            lineNumber = 0,
            lineHeight = 1.1
          while (word = words.shift()) {
            if (getTextWidth(currentLine + word, "10px sans-serif") < width) {
              // We're safe to add the word
              currentLine += word + ' ';
            } else {
              // If we add the word, we exceed the line length
              // Trim to remove the last space
              lines.push('<tspan x="0" y="9" dy="' + (++lineNumber * lineHeight) + 'em">' + currentLine.trim() + '</tspan>')
              currentLine = word + ' ';
            }
          }

          lines.push('<tspan x="0" y="9" dy="' + (++lineNumber * lineHeight) + 'em">' + currentLine.trim() + '</tspan>')
          return lines.join('');
        });
      });
    }

    // Labels of row and columns -> unique identifier of the column called 'group' and 'variable'
    var motif1s = d3.map(data, function (d) { return d.motif1; }).keys()
    var motif2s = d3.map(data, function (d) { return d.motif2; }).keys()

    // Build X scales and axis:
    var x = d3.scaleBand()
      .range([0, width])
      .domain(motif1s)
      .padding(0.05);
    svg.append("g")
      .attr("id", "xAxis")
      .style("font-size", d3.min([8, x.bandwidth()]))
      .attr("transform", "translate(0," + height + ")")
      // .call(d3.axisBottom(x).tickSize(0))
      // .select(".domain").remove()
      .call(d3.axisBottom(x).tickSize(0))
      .style("text-anchor", "end")
      .selectAll("text")
      .attr("dx", "-.8em")
      .attr("dy", ".5em")
      .attr("transform", "rotate(-60)")

    // Build Y scales and axis:
    var y = d3.scaleBand()
      .range([height, 0])
      .domain(motif2s)
      .padding(0.05);
    svg.append("g")
      .attr("id", "yAxis")
      .style("font-size", d3.min([8, y.bandwidth()]))
      .call(d3.axisLeft(y).tickSize(0))
      // .select(".domain").remove()
      .style("text-anchor", "end")
      .selectAll("text")
      .attr("dx", "-.8em")
      .attr("dy", ".5em")
      .attr("transform", "rotate(-60)")

    // create a tooltip
    // var tooltip = d3.select("#placeholder")
    var tooltip = d3.select(svgID)
      .append("div")
      .style("opacity", 0)
      .attr("class", "tooltip")
      .style("background-color", "white")
      .style("border", "solid")
      .style("border-width", "1px")
      .style("border-radius", "5px")
      .style("padding", "1px")

    var colorsMin = ["#FFFFFF", "#fde7e7", "#a2d5f5", "#baeed3", "#f9cb8b", "#f2d1ea", "#47484c"];
    var colorsMax = ["#FFFFFF", "#f26969", "#11659a", "#1a6840", "#f9a633", "#cd47aa", "#2f2f35"]

    // add the squares
    svg.selectAll()
      .data(data, function (d) { return d.motif1 + ':' + d.motif2; })
      .enter()
      .append("rect")                                   // attach a rectangle
      .attr("class", heatmapID)
      .attr("x", function (d) { return x(d.motif1) })   // position the left of the rectangle
      .attr("y", function (d) { return y(d.motif2) })   // position the top of the rectangle
      .attr("rx", 1)                                    // set the x radius
      .attr("ry", 1)                                    // set the y radius
      .attr("width", x.bandwidth())                     // set the width
      .attr("height", y.bandwidth())                    // set the height
      .style("fill", function (d) {

        var clu = (cluster_motif !== null) ? cluster_motif : d.cluster
        var colorIndex = clusters.indexOf(clu)

        var myColor = d3.scaleLinear()
          .range([colorsMin[colorIndex + 1], colorsMax[colorIndex + 1]])
          .domain([valMin, valMax])

        return myColor(d.p_adj)
      })
      .style("stroke-width", 1)
      .style("stroke", "none")                          // colour the line
      // .style("opacity", 0.8)
      // .style("fill", function (d) {return someColors(d.source.group)})
      // .style("fill-opacity", function (d) {return d.weight * .8});
      .on("mouseover", mouseover)
      .on("mousemove", mousemove)
      .on("mouseleave", mouseleave)
    // .on("click", mouseclick)

    // // Add title to graph
    // svg.append("text")
    //   .attr("x", 0)
    //   .attr("y", -50)
    //   .attr("text-anchor", "left")
    //   .style("font-size", "22px")
    //   .text("A d3.js heatmap");

    // // Add subtitle to graph
    // svg.append("text")
    //   .attr("x", 0)
    //   .attr("y", -20)
    //   .attr("text-anchor", "left")
    //   .style("font-size", "14px")
    //   .style("fill", "grey")
    //   .style("max-width", 400)
    //   .text("A short description of the take-away message of this chart.");

    return svg;
  }
});