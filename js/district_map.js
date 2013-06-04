// Generated by CoffeeScript 1.4.0
var DistrictMap, GeoReceiver, HistoricMapData, HistoryMap, HistoryReceiver, MapControls, MapData, MapStyle, ReportReceiver, StatTable, server_url,
  _this = this;

server_url = "http://localhost:8000";

StatTable = {
  initialize: function() {
    var count, district, key, name, table, _ref, _ref1, _results;
    _ref = ReportReceiver.district_map;
    for (key in _ref) {
      district = _ref[key];
      table = "<tr><td>" + district.name + "</td><td>" + ReportReceiver.crime_stat[key] + "</td></tr>";
      $('.recent-stat-table tbody').append(table);
    }
    _ref1 = HistoryReceiver.crime_stat;
    _results = [];
    for (name in _ref1) {
      count = _ref1[name];
      table = "<tr><td>" + name + "</td><td>" + count + "</td></tr>";
      _results.push($('.history-stat-table tbody').append(table));
    }
    return _results;
  }
};

DistrictMap = {
  map: null,
  district_layer: null,
  initialize: function() {
    var epsg4326, epsg900913, layer;
    epsg4326 = new OpenLayers.Projection('EPSG:4326');
    epsg900913 = new OpenLayers.Projection('EPSG:900913');
    this.map = new OpenLayers.Map('map', {
      projection: epsg900913,
      displayProjection: epsg4326
    });
    layer = new OpenLayers.Layer.OSM();
    this.map.addLayer(layer);
    this.map.setCenter(new OpenLayers.LonLat(13.4, 52.5).transform(epsg4326, epsg900913), 10);
    return this.add_district_layer();
  },
  center_map: function(center_x, center_y) {
    return this.map.setCenter((new OpenLayers.LonLat(center_x, center_y)).transform("EPSG:4326", "EPSG:900913"), 8);
  },
  add_district_layer: function() {
    var features;
    this.district_layer = new OpenLayers.Layer.Vector("Berlin Districts");
    this.district_layer.removeAllFeatures();
    features = MapData.district_feature_collection();
    this.district_layer.addFeatures(features);
    return this.map.addLayer(this.district_layer);
  }
};

HistoryMap = {
  map: null,
  district_layer: null,
  initialize: function() {
    var epsg4326, epsg900913, layer;
    epsg4326 = new OpenLayers.Projection('EPSG:4326');
    epsg900913 = new OpenLayers.Projection('EPSG:900913');
    this.map = new OpenLayers.Map('history_map', {
      projection: epsg900913,
      displayProjection: epsg4326
    });
    layer = new OpenLayers.Layer.OSM();
    this.map.addLayer(layer);
    this.map.setCenter(new OpenLayers.LonLat(13.4, 52.5).transform(epsg4326, epsg900913), 10);
    return this.add_district_layer();
  },
  add_district_layer: function() {
    var features;
    this.district_layer = new OpenLayers.Layer.Vector("Berlin History Districts");
    this.district_layer.removeAllFeatures();
    features = HistoricMapData.district_feature_collection();
    this.district_layer.addFeatures(features);
    return this.map.addLayer(this.district_layer);
  }
};

HistoricMapData = {
  district_feature_collection: function() {
    var district, feature, featurecollection, geojson_format, style, _i, _len, _ref;
    featurecollection = [];
    geojson_format = new OpenLayers.Format.GeoJSON();
    _ref = MapData.map_data;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      district = _ref[_i];
      feature = {
        "geometry": null,
        "type": "Feature",
        "properties": {}
      };
      style = MapStyle.style(this.district_color(HistoryReceiver.crime_stat[district.name]));
      feature.geometry = district['area'];
      feature = geojson_format.parseFeature(feature);
      feature.style = style;
      featurecollection.push(feature);
    }
    return featurecollection;
  },
  district_color: function(count) {
    var colors, i, quantil, _i, _len, _ref;
    colors = ['#00ff00', '#ffff00', '#df7401', "#ff0000"];
    if (!(count != null)) {
      count = 0;
    }
    i = 0;
    _ref = this.quantils();
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      quantil = _ref[_i];
      if (count < quantil) {
        break;
      }
      i++;
    }
    return colors[i];
  },
  quantils: function() {
    return [25000, 35000, 55000];
  }
};

MapData = {
  map_data: [],
  weighted: false,
  district_feature_collection: function() {
    var district, feature, featurecollection, geojson_format, style, _i, _len, _ref;
    featurecollection = [];
    geojson_format = new OpenLayers.Format.GeoJSON();
    _ref = this.map_data;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      district = _ref[_i];
      feature = {
        "geometry": null,
        "type": "Feature",
        "properties": {}
      };
      style = MapStyle.style(this.district_color(ReportReceiver.crime_stat[district.resource_uri]));
      feature.geometry = district['area'];
      feature = geojson_format.parseFeature(feature);
      feature.style = style;
      featurecollection.push(feature);
    }
    return featurecollection;
  },
  district_color: function(count) {
    var colors, i, quantil, _i, _len, _ref;
    colors = ['#00ff00', '#ffff00', '#df7401', "#ff0000"];
    if (!(count != null)) {
      count = 0;
    }
    i = 0;
    _ref = this.quantils();
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      quantil = _ref[_i];
      if (count < quantil) {
        break;
      }
      i++;
    }
    return colors[i];
  },
  quantils: function() {
    if (this.weighted) {
      return [1, 3, 5];
    } else {
      return [1, 3, 5];
    }
  }
};

MapStyle = {
  renderer: function() {
    var renderer;
    return renderer = OpenLayers.Layer.Vector.prototype.renderers;
  },
  layer_style: function() {
    var layer_style;
    layer_style = OpenLayers.Util.extend({}, OpenLayers.Feature.Vector.style['default']);
    layer_style.fillOpacity = 0.3;
    layer_style.graphicOpacity = 1;
    return layer_style;
  },
  style: function(color) {
    var style;
    style = OpenLayers.Util.extend({}, this.layer_style());
    style.strokeColor = color;
    style.fillColor = color;
    return style;
  }
};

MapControls = {
  toggle_district_layer: function() {
    var button;
    button = $('#button');
    if (button.text() === "Change to Weighted") {
      MapData.weighted = true;
      button.text('Change to Normal');
    } else {
      MapData.weighted = false;
      button.text('Change to Weighted');
    }
    return DistrictMap.add_district_layer();
  },
  update_legend: function() {
    var i, quantil, quantils, _i, _len;
    i = 0;
    quantils = MapData.quantils();
    for (_i = 0, _len = quantils.length; _i < _len; _i++) {
      quantil = quantils[_i];
      $("#quantil" + i).text("less than " + quantil);
      i++;
    }
    return $("#quantil3").text("greater than or equal to " + quantils[2]);
  }
};

GeoReceiver = {
  init: function() {
    var settings;
    settings = {
      dataType: 'jsonp',
      url: "" + server_url + "/api/v1/districts/?community__state__name=Berlin",
      success: GeoReceiver.process_districts
    };
    return $.ajax(settings);
  },
  process_districts: function(data) {
    var settings;
    MapData.map_data = MapData.map_data.concat(data['objects']);
    if (data.meta.next != null) {
      settings = {
        dataType: 'jsonp',
        url: server_url + data.meta.next,
        success: GeoReceiver.process_districts
      };
      return $.ajax(settings);
    } else {
      return ReportReceiver.init();
    }
  }
};

ReportReceiver = {
  berlin_bbox: null,
  reports: [],
  crime_stat: {},
  district_map: {},
  init: function() {
    var settings;
    settings = {
      dataType: 'jsonp',
      url: "" + server_url + "/api/v1/states/?name=Berlin",
      success: ReportReceiver.process_state
    };
    return $.ajax(settings);
  },
  process_state: function(data) {
    var settings;
    _this.berlin_bbox = data.objects[0].bbox;
    settings = {
      dataType: 'jsonp',
      url: ("" + server_url + "/api/v1/reports/?location__within=") + JSON.stringify(_this.berlin_bbox),
      success: ReportReceiver.get_reports
    };
    return $.ajax(settings);
  },
  get_reports: function(data) {
    var settings;
    ReportReceiver.reports = ReportReceiver.reports.concat(data.objects);
    if (data.meta.next != null) {
      settings = {
        dataType: 'jsonp',
        url: server_url + data.meta.next,
        success: ReportReceiver.get_reports
      };
      return $.ajax(settings);
    } else {
      return ReportReceiver.process_reports();
    }
  },
  process_reports: function() {
    var report, settings, _i, _len, _ref, _results;
    settings = {
      dataType: 'jsonp',
      success: ReportReceiver.update_crime_stat
    };
    ReportReceiver.open_report_requests = ReportReceiver.reports.length;
    _ref = ReportReceiver.reports;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      report = _ref[_i];
      settings.url = ("" + server_url + "/api/v1/districts/?area__contains=") + JSON.stringify(report.location);
      _results.push($.ajax(settings));
    }
    return _results;
  },
  update_crime_stat: function(data) {
    if (data.objects.length > 0) {
      if (!(ReportReceiver.crime_stat[data.objects[0].resource_uri] != null)) {
        ReportReceiver.district_map[data.objects[0].resource_uri] = data.objects[0];
        ReportReceiver.crime_stat[data.objects[0].resource_uri] = 1;
      } else {
        ReportReceiver.crime_stat[data.objects[0].resource_uri] += 1;
      }
    }
    ReportReceiver.open_report_requests -= 1;
    if (ReportReceiver.open_report_requests <= 0) {
      DistrictMap.initialize();
      return HistoryReceiver.init();
    }
  }
};

HistoryReceiver = {
  crime_stat: {},
  init: function() {
    var settings;
    settings = {
      dataType: 'jsonp',
      url: "" + server_url + "/api/v1/history/",
      success: HistoryReceiver.get_reports
    };
    return $.ajax(settings);
  },
  get_reports: function(data) {
    var district, _i, _len, _ref;
    _ref = data.objects;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      district = _ref[_i];
      HistoryReceiver.crime_stat[district.name] = district.count;
    }
    return StatTable.initialize();
  }
};

jQuery(function() {
  GeoReceiver.init();
  return $('button').click(function() {
    return MapControls.toggle_district_layer();
  });
});
