
https://d3-graph-gallery.com/graph/heatmap_style.html

-   The Html part of the code just creates a `div` that will be modified by d3 later on.
  
-   The first part of the javascript code set a `svg` area. It specify the chart size and its margin. [Read more](https://d3-graph-gallery.com/graph/heatmap_style.html).
  
-   A [dummy dataset](https://raw.githubusercontent.com/holtzy/D3-graph-gallery/master/DATA/heatmap_data.csv) has been created for this example, at the long format. (3 columns: row, col, value).
  
-   The first step is to build scales and axis. Thus each entity will have a position on the grid.
  
-   A `scaleBand()` is used, which allows to control the size of each square using the `padding property`. If padding is close from 1, square are very small. (0 for very big)
  
-   Finally, each square can be added using a `rect` element.