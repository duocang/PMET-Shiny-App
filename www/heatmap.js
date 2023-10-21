//Code comes from https://bl.ocks.org/mbostock/1389927

//Wrap the entire D3 script in this function. It is looking for a jsondata message sent from Shinys server session object.
Shiny.addCustomMessageHandler('jsondata', function (pmet) {

  //Lets nuke out any thing on our page with the id of "d3Temp". This will prevent
  d3.select("#d3Temp").remove();
  const d3Placeholder = document.getElementById("placeholder");
  const d3Temp = document.createElement("div");
  d3Temp.id = "d3Temp";
  d3Placeholder.appendChild(d3Temp);

  var clusters = pmet.clusters;

  if (pmet.method == "All") {
    console.log("All clusters")
    var valMax = 0;
    var valMin = 0;

    for (var id of clusters) {
      var dataFiltered = pmet.data[id].filter(function (dat) { return dat.gene_num > 0 })
      valMax = Math.max(valMax, Math.max(...dataFiltered.map(o => o.p_adj)));
      valMin = Math.min(valMin, Math.min(...dataFiltered.map(o => o.p_adj)));
    }

    for (var id of clusters) {
      // append the svg object to the body of the page

      var colorInd = clusters.indexOf(id);

      var svgHeatmap = DrawHeatmap( data       = pmet.data[id],
                                    sagID      = "#d3Temp",
                                    heatmapID  = id,
                                    valMax     = valMax,
                                    valMin     = valMin,
                                    colorIndex = colorInd,
                                    motifs     = pmet.motifs)
    }
  } else if (pmet.method == "Aggregation") {
    var ids = Object.keys(pmet.data);

    // // set the dimensions and margins of the graph
    // var margin = { top: 10, right: 50, bottom: 120, left: 150 },
    //   width = 500 - margin.left - margin.right,
    //   height = 400 - margin.top - margin.bottom;

    // var valMax = 0;
    // var valMin = 0;

    // for (var id1 of pmet.clusters) {
    //   for (var id2 of pmet.clusters) {
    //     var id = id1 + "_" + id2
    //     var dataFiltered = pmet.data[id].filter(function (dat) { return dat.gene_num > 0 })

    //     valMax = Math.max(valMax, Math.max(...dataFiltered.map(o => o.p_adj)))
    //     valMin = Math.min(valMin, Math.min(...dataFiltered.map(o => o.p_adj)))
    //   }


    //   for (var id2 of pmet.clusters) {
    //     var id = id1 + "_" + id2

    //     // append the svg object to the body of the page
    //     var mainsvg = d3.select("#placeholder")
    //       .append("svg")
    //       .attr("id", "mainsvg-" + id)
    //       .attr("width", width + margin.left + margin.right)
    //       .attr("height", height + margin.top + margin.bottom)
    //       .append("g")
    //       .attr("transform",
    //         "translate(" + margin.left + "," + margin.top + ")");

    //     var svgHeatmap = DrawHeatmap(data = pmet.data[id],
    //       svg = mainsvg,
    //       svgID = "#placeholder",
    //       heatmapID = "rect" + id,
    //       valMax = valMax,
    //       valMin = valMin,
    //       clusters = pmet.clusters,
    //       cluster_motif = id1)
    //   }
    // }
  } else if (pmet.method == "Overlap") {
    console.log("Overlapping");
    var dataFiltered = pmet.data.filter(function (dat) { return dat.gene_num > 0 })

    var valMax = Math.max(...dataFiltered.map(o => o.p_adj))
    var valMin = Math.min(...dataFiltered.map(o => o.p_adj))

    var svgHeatmap = DrawHeatmap( data       = pmet.data,
                                  svgID      = "#d3Temp",
                                  heatmapID  = pmet.method[0],
                                  valMax     = valMax,
                                  valMin     = valMin,
                                  colorIndex = -1,          // different clolors for different clusters
                                  motifs     = pmet.motifs)
  } else {
    var dataFiltered = pmet.data.filter(function (dat) { return dat.gene_num > 0 })

    var valMax = Math.max(...dataFiltered.map(o => o.p_adj))
    var valMin = Math.min(...dataFiltered.map(o => o.p_adj))

    var colorInd = clusters.indexOf(pmet.method[0]);

    var svgHeatmap = DrawHeatmap( data       = pmet.data,
                                  svgID      = "#d3Temp",
                                  heatmapID  = pmet.method,
                                  valMax     = valMax,
                                  valMin     = valMin,
                                  colorIndex = colorInd,
                                  motifs     = pmet.motifs)
  }
  function GenerateArray(n) {
    return Array.from({ length: n }, (_, index) => index + 1);
  }


  function GenerateRange(start, end, steps) {
    const range = [];
    const stepSize = (end - start) / (steps - 1);
    for (let i = 0; i < steps; i++) {
      const value = (start + i * stepSize).toFixed(1);
      range.push(value);
    }
    return range;
  }

  function DrawHeatmap(data, svgID, heatmapID, valMax = 0, valMin = 0, colorIndex = null, motifs = null) {

    var maxLength = motifs.reduce(function (max, str) {
      return str.length > max ? str.length : max;
    }, 0);
    console.log(maxLength)

    // top margin automatically fit heatmap in overlap mode because heatmap with overlap can have many
    // catagory ledgeds
    if (colorIndex == -1) { // overlap heatmap
      if (clusters.length >= 4) {
        var topMargin = 20 * clusters.length
      } else if (clusters.length == 3) {
        var topMargin = 25 * clusters.length
      } else if (clusters.length == 2) {
        var topMargin = 30 * clusters.length
      } else {
        var topMargin = 20;
      }

    } else {                // non-overlap heatmap
      var topMargin = 40;
    }

    if (motifs.length < 7 && motifs.length > 4) {
      var cellSizeBigger = 25
    } else if (motifs.length <= 4) {
      var cellSizeBigger = 50
    } else {
      var cellSizeBigger = 20
    }
    // Consider 1 `pt` to be approximately 0.75 `px`.
    var margin = { top: topMargin, right: 0, bottom: maxLength * 8 , left: maxLength * 8 },
        cellSize = cellSizeBigger;
        col_number = motifs.length,
        row_number = motifs.length,
        width    = cellSize * col_number, // - margin.left - margin.right,
        height   = cellSize * row_number, // - margin.top - margin.bottom,
        rowLabel = motifs,
        colLabel = motifs;

    var hcrow = GenerateArray(row_number),
        hccol = GenerateArray(col_number);

    var colorsMin = ["#fde7e7", "#a2d5f5", "#baeed3", "#fcead0", "#f2d1ea", "#47484c"],
        colorsMax = ["#a61b29", "#11659a", "#1a6840", "#f9a633", "#cd47aa", "#2f2f35"];

    if (colorIndex == -1) {
      var myColor = d3.scale.linear()
        .range([colorsMin[0], colorsMax[0]])
        .domain([valMin, valMax])
    } else {
      var myColor = d3.scale.linear()
        .range([colorsMin[colorIndex], colorsMax[colorIndex]])
        .domain([valMin, valMax])
    }

    var svg = d3.select(svgID).append("svg")
      .attr("id", "heatmap-" + heatmapID)
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
      .append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")")
        ;

    var tooltip = d3.select("heatmap-" + heatmapID)
      .append("div")
      .style("opacity", 0)
      .attr("class", "tooltip")
      .style("background-color", "white")
      .style("border", "solid")
      .style("border-width", "1px")
      .style("border-radius", "5px")
      .style("padding", "1px")


    var rowSortOrder = false;
    var colSortOrder = false;
    var rowLabels = svg.append("g")
      // .attr("id", "rowLabelg-" + heatmapID)
      .selectAll(".rowLabelg")
      .data(rowLabel)
      .enter()
      .append("text")
      .text(function (d) { return d; })
      .attr("x", 0)
      .attr("y", function (d, i) { return hcrow.indexOf(i + 1) * cellSize; })
      .style("text-anchor", "end")
      .attr("transform", "translate(-6," + cellSize / 1.5 + ")")
      .attr("class", function (d, i) { return "rowLabel mono r" + (i + 1) + " rowLabel-" + heatmapID; })
      .on("mouseover", function (d) { d3.select(this).classed("text-hover", true); })
      .on("mouseout", function (d) { d3.select(this).classed("text-hover", false); })
      .on("click", function (d, i) {
        rowSortOrder = !rowSortOrder;
        sortbylabel("r", i, rowSortOrder);
        d3.select("#order").property("selectedIndex", 4).node().focus();
      })
      ;

    var colLabels = svg.append("g")
      // .attr("id", "colLabelg-" + heatmapID)
      .selectAll(".colLabelg")
      .data(colLabel)
      .enter()
      .append("text")
      .text(function (d) { return d; })
      .attr("x", function (d, i) { return -height-13;})
      .attr("y", function (d, i) { return hccol.indexOf(i + 1) * cellSize+3; })
      .style("text-anchor", "end")
      .attr("transform", "translate(" + cellSize / 2 + ",-6) rotate (-90)")
      .attr("class"  , function (d, i) { return "colLabel mono c" + (i + 1) + " colLabel-" + heatmapID; })
      .on("mouseover", function (d   ) { d3.select(this).classed("text-hover", true); })
      .on("mouseout" , function (d   ) { d3.select(this).classed("text-hover", false); })
      ;

    var heatMap = svg.append("g").attr("class", "g3")
      .selectAll(".cellg")
      .data(data, function (d) { return d.motif1 + ":" + d.motif2; })
      .enter()
      .append("rect")
      .attr("x",     function (d) { return hccol.indexOf(d.motif1) * cellSize; })
      .attr("y",     function (d) { return hcrow.indexOf(d.motif2) * cellSize; })
      .attr("class", function (d) { return "cell cell-border cr" + (d.motif1) + " cc" + (d.motif2); })
      .attr("width", cellSize)
      .attr("height", cellSize)
      .style("fill", function (d) {
        // heatmap overlap, different colors for different clusters
        if (colorIndex === -1) {
          indx = clusters.indexOf(d.cluster);

          var myColor_ = d3.scale.linear()
            .range([colorsMin[indx], colorsMax[indx]])
            .domain([valMin, valMax])

          if (d.p_adj !== null) {
            return myColor_(d.p_adj);
          } else {
            return "white";
          }

        } else {
          if (d.p_adj !== null) {
            return myColor(d.p_adj);
          } else {
            return "white";
          }
        }
      })
      .on("click", function(d) {
        // Create a modal element
        var modal = d3.select("body")
          .append("div")
          .attr("class", "modal")
          .style("display", "block");
        // Create a modal content container
        var modalContent = modal.append("div")
          .attr("class", "modal-content");
        // Add a close button to the modal content container
        modalContent.append("span")
          .attr("class", "close")
          .html("&times;")
          .on("click", function() {
            modal.remove();
          });

        // Add the data to the modal content container
        modalContent.append("p")
          .attr("class", "cluster-text")
          .text("Cluster: " + d.cluster);
        modalContent.append("p")
          .html("Motif 1: <span class='bold-text'>" + motifs[d.motif1 - 1] + "</span>");
        modalContent.append("p")
          .html("Motif 2: <span class='bold-text'>" + motifs[d.motif2 - 1] + "</span>");
        modalContent.append("p")
          .text("Gene number: " + d.gene_num);

        // Format genes data
        var formattedGenes = d.genes.replace(/;/g, " ").trim();
        var genesArray = formattedGenes.split(" ");
        var genesPerLine = 5;
        var genesText = "";
        for (var i = 0; i < genesArray.length; i++) {
          genesText += genesArray[i] + " ";
          if ((i + 1) % genesPerLine === 0) {
            genesText += "\n";
          }
        }

        modalContent.append("p")
          .attr("class", "genes-text")
          .text("Genes: ")
          .append("pre")
          .html(genesText.split('\n').map(function (line, index) {
            var lineNumber = (index * genesPerLine) + 1;
            return '<span class="line-number" data-line-number="' + lineNumber + '"></span>' + line;
          }).join('\n'));
      })

      .on("mouseover", function (d) {
        //highlight text
        d3.select(this).classed("cell-hover", true);
        d3.selectAll(".rowLabel-" + heatmapID).classed("text-highlight", function (r, ri) { return ri == (d.motif2 - 1); });
        d3.selectAll(".colLabel-" + heatmapID).classed("text-highlight", function (c, ci) { return ci == (d.motif1 - 1); });
        //Update the tooltip position and value
        d3.select("#tooltip")
          .style("left", (d3.event.pageX - 340) + "px")
          .style("top" , (d3.event.pageY - 220) + "px")
          .select("#value")
          .html("<b>motif x</b>: "       + motifs[d.motif1 - 1] + "<br>" +
                "<b>motif y</b>: "       + motifs[d.motif2 - 1] + "<br>" +
                "<b>cluster</b>  :"      + d.cluster            + "<br>" +
                "<b>-log10(p.adj)</b>: " + d.p_adj              + "<br>" +
                "<b># genes</b>: "       + d.gene_num           + "<br>" +//+  "<b>genes</b>:<br>" + "&nbsp;&nbsp;&nbsp;&nbsp;" + d.genes
                "<hr>" +
                "Click for details"
          )
        if (d.p_adj !== null) {
          //Show the tooltip
          d3.select("#tooltip").classed("hidden", false);
        }
      })
      .on("mouseout", function () {
        d3.select(this).classed("cell-hover", false);
        d3.selectAll(".rowLabel").classed("text-highlight", false);
        d3.selectAll(".colLabel").classed("text-highlight", false);
        d3.select("#tooltip").classed("hidden", true);
      })
      ;

    if (valMin === valMax) {
      var legendNums= [valMax.toFixed(1)];
    } else {
      var legendNums = GenerateRange(valMin, valMax, 5);
    }

    // manuallyh set cell sieze to 12 in case the number cahnged when too few motifs
    cellSize = 12;
    var fontSize = cellSize + 3;

    var legend = svg.selectAll(".legend")
      .data(legendNums)
      .enter().append("g")
      .attr("class", "legend");

    if (heatmapID == "Overlap") {

      for (let clusterIndex = 0; clusterIndex < clusters.length; clusterIndex++) {

          var colorCluster = d3.scale.linear()
            .range([colorsMin[clusterIndex], colorsMax[clusterIndex]])
            .domain([valMin, valMax])

          legend.append("rect")
            .attr("x"     , function (d, i) { return cellSize * i; })
            .attr("y"     , -cellSize* (2+clusterIndex))
            .attr("width" ,  cellSize)
            .attr("height",  cellSize)
            .style("fill" , function (d, i) { return colorCluster(legendNums[i]); });
          // add catagory/cluster on top of heamap
          legend.append("text")
            .attr("class", "mono")
            .text(clusters[clusterIndex])
            .style("font-size", fontSize + "px")
            .style("font-weight", "bold")
            .style("fill", colorsMax[clusterIndex])
            .attr("x"    , function (d, i) { return cellSize * 6; })
            .attr("y"    , -cellSize * (clusterIndex + 1.2));
      }
      // add title for legend
      legend.append("text")
        .attr("width", fontSize)
        .attr("x", 0)
        .attr("y", -cellSize*(2 + clusters.length))
        .text("-log10(p-val)")
        .attr("font-family", "Consolas, courier")
        .attr("font-size", "12px")
        .attr("fill", "#aaa")
      console.log(heatmapID)
    } else {
      legend.append("rect")
        .attr("x"     , function (d, i) { return cellSize * i; })
        .attr("y"     , -cellSize*2)
        .attr("width" , cellSize)
        .attr("height", cellSize)
        .style("fill" , function (d, i) { return myColor(legendNums[i]); });

      // add title for legend
      legend.append("text")
        .attr("width", fontSize)
        .attr("x", 0)
        .attr("y", -cellSize*2.7)
        .text("-log10(p-val)")
        .attr("font-family", "Consolas, courier")
        .attr("font-size", "12px")
        .attr("fill", "#aaa")

      legend.append("text")
        .attr("class", "mono")
        .text(heatmapID)
        .style("font-size", fontSize * 1.2 + "px")
        .style("font-weight", "bold")
        .style("fill", colorsMax[colorIndex])
        .attr("x"    , function (d, i) { return cellSize * 6; })
        .attr("y"    , -cellSize * 1.2);

    }
    legend.append("text")
      .attr("class", "mono")
      .text(function (d) {
        // only show min and max values of legend
        if (d === legendNums[0] || d === legendNums[4]) {
          return Math.floor(d);
        }
      })
      // .attr("width", fontSize)
      .attr("x", function (d, i) { return cellSize * i; })
      .attr("y", 0);
  }
});
