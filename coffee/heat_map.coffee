OsmHeatMap =
  map: undefined
  initialize: ->
    epsg4326 = new OpenLayers.Projection('EPSG:4326')
    epsg900913 = new OpenLayers.Projection('EPSG:900913')
    @.map = new OpenLayers.Map('heat_map', projection: epsg900913, displayProjection: epsg4326)
    layer = new OpenLayers.Layer.OSM()
    @.map.addLayer layer
    @.map.setCenter(new OpenLayers.LonLat(13, 52).transform(epsg4326, epsg900913), 8)

    #@.add_district_layer()
    @.add_heatmap_layer()



  add_district_layer: ->

    vectorLayer = new OpenLayers.Layer.Vector("Berlin Districts",  { style: MapStyle.layer_style(), renderers: MapStyle.renderer() } )
    features = MapData.district_feature_collection()
    for feature in features
      feature.style.fillColor = 'white'
      feature.style.strokeColor = 'white'
    vectorLayer.addFeatures(features)
    @.map.addLayer(vectorLayer)

  add_heatmap_layer: ->
    epsg4326 = new OpenLayers.Projection('EPSG:4326')
    epsg900913 = new OpenLayers.Projection('EPSG:900913')
    crime_data =
      max: 10,
      data: []
    for report in ReportReceiver.reports
      for x in [0..10]
        crime_data.data.push
          lonlat: new OpenLayers.LonLat(13, 52)#new OpenLayers.LonLat(report.location.coordinates[0], report.location.coordinates[1]).transform(epsg900913 ,epsg4326)
    heatmapLayer = new OpenLayers.Layer.Heatmap("Heatmap Layer", @.map, crime_data, {visible: true, radius: 40}, {isBaseLayer: false, opacity: 0.6})
    @.map.addLayer(heatmapLayer)



MapStyle =
  renderer: ->
    renderer = OpenLayers.Util.getParameters(window.location.href).renderer
    renderer = (if (renderer) then [renderer] else OpenLayers.Layer.Vector::renderers)

  layer_style: ->
    layer_style = OpenLayers.Util.extend({}, OpenLayers.Feature.Vector.style['default'])
    layer_style.fillOpacity = 0.3
    layer_style.graphicOpacity = 1
    layer_style

  style: (color) ->
    style = OpenLayers.Util.extend({}, @.layer_style())
    style.strokeColor = color
    style.fillColor = color
    style

