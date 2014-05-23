# Copyright 2014 YMC. See LICENSE for details.

class @TableRegionsChartView extends Backbone.View

  initialize: ->
    @table = @options.table
    @palette = @options.palette
    @collection.on "reset", _.bind(@render, @)
    @series = []

  render: ->
    if @collection.isZeroLength()
      regions = @collection.reduce((memo, region) ->
        "#{memo}<li><a href=\"#{Routes.Regions.show({name:region.get('regionURI')})}\">#{region.get('regionName')}<a/></li>"
      , "" )
      @$el.html("The table #{@table.name} seems to have not any data yet, it contains the regions:<ul>#{regions}</ul>")
    else
      RickshawUtil.mergeSeriesData([@createSeries(@table.name, @collection)], @series)
      if !@graph
        @createGraph()
      else
        @updateGraph()


  createGraph: ->
    @graph =  new Rickshaw.Graph
      element: @$(".chart")[0],
      series: @series
      renderer: 'bar'

    minExponent = RickshawUtil.getHumanReadableExponent(_.max(@series[0].data, (data) -> data.y).y * 1024 * 1024)

    @yAxis = new Rickshaw.Graph.Axis.Y
      graph: @graph,
      orientation: 'left',
      element: @$(".y-axis")[0]
      tickFormat: (val) -> if val > 0 then RickshawUtil.humanReadableBytes(val * 1024 * 1024, minExponent) else 0

    @xAxis = new RickshawUtil.LeftAlignedXAxis
      graph: @graph,
      element: @$(".x-axis")[0]
      tickFormat: (x) => if x < @collection.length && x % 1 == 0 then "##{x+1}" else ""

    @legend = new Rickshaw.Graph.Legend
      graph: @graph
      element: @$(".legend")[0]


    @threshold = @table.maxFileSize / 1024 / 1024
    @thresholdLine = new RickshawUtil.ThresholdLine
      graph: @graph
      legend: @legend
      threshold: @threshold
      name: "Split Size"
      color: "#ff0000"
      disabled: @threshold > @collection.at(0).get('storefileSizeMB') * 2

    @shelving = new Rickshaw.Graph.Behavior.Series.Toggle
      graph: @graph
      legend: @legend

    @hoverDetail = new RickshawUtil.InteractiveHoverDetail
      graph: @graph
      xFormatter: ((x) =>
        if x >= @collection.length
          ""
        else
          region = @collection.at(x)
          "##{x+1} : #{region.get('regionName')}"
      )
      yFormatter: ((y) => y)
      formatter: ((series, x, y, formattedX, formattedY, d) =>
        region = d.value.region
        headline = "<b>" + region.get('startKey') + "</b>"
        host = "Host:&nbsp;" + region.get('serverHostName')
        storefileSize = "Size (MB):&nbsp;" + region.get("storefileSizeMB").toFixed(0)
        storefiles = "Storefiles:&nbsp;" + region.get("storefiles")
        headline + "<br>" + host + "<br>" + storefileSize + "<br>" + storefiles
      )
      onClick: (series) =>
        document.location.href = Routes.Regions.show
          name: series.value.region.get('regionURI')

    @graph.render()

  updateGraph: ->
    @graph.update()
    @graph.render()

  createSeries: (name, regions) ->
    minSize = regions.max((region) -> region.get('storefileSizeMB')).get('storefileSizeMB') / 100
    series = {
      name: "Storefile Size (MB)"
      data: regions.map((region, x) ->
        y = region.get('storefileSizeMB')
        return {
          x: x
          y: if y > minSize then y else minSize
          region: region
        }
      ),
      noLegend: true
      color: @palette.color(name)
    }

    # Add another datapoint because the bar-renderer won't render anything when there is only one datapoint
    if series.data.length == 1
      series.data.push {
        x: 1
        y: 0
        region: series.data[0].region
      }
    series
