// Generated by CoffeeScript 1.4.0
var init_heat_map, init_history_map;

init_heat_map = function() {
  return OsmHeatMap.initialize();
};

init_history_map = function() {
  return HistoryMap.initialize();
};

$('#heat_link').click(function() {
  return setTimeout(init_heat_map, 100);
});

$('#history_link').click(function() {
  return setTimeout(init_history_map, 100);
});
