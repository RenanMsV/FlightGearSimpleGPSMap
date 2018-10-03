var DEBUG = 0;
var (width,height) = (768,512);
var tile_size = 256;
var alpha = 1;
var zoom = 14;
var gps_map = "nil";
var bright = 1;

var types = [
	{
		minmaxzoom : [2,19],
		type : "intl",
		urlTemplate : "https://maps.wikimedia.org/osm-{type}/{z}/{x}/{y}.png",
		urlPath : "/osm-{type}/{z}/{x}/{y}.png"
	},
	{
		minmaxzoom : [2,14],
		type : "terrain",
		urlTemplate : "http://a.tile.stamen.com/{type}/{z}/{x}/{y}.png",
		urlPath : "/{type}/{z}/{x}/{y}.png"
	}
];

var currentTypeID = 0;

var show_map = func (){

	var window = canvas.new({
  		"name": "GPSMap",   # The name is optional but allow for easier identification
  		"size": [width, height], # Size of the underlying texture (should be a power of 2, required) [Resolution]
  		"view": [width, height],  # Virtual resolution (Defines the coordinate system of the canvas [Dimensions]
                        # which will be stretched the size of the texture, required)
  		"mipmapping": 1       # Enable mipmapping (optional)
  	});

	window.addPlacement({"node": "FGBR_GPS_SCREEN"});
	var g = window.createGroup();

	var type = types[currentTypeID].type;

	var ui_root = window.createGroup();
	var vbox = canvas.VBoxLayout.new();
	window.setLayout(vbox);

	var changeZoom = func(d)
	{
		zoom = math.max(types[currentTypeID].minmaxzoom[0], math.min(types[currentTypeID].minmaxzoom[1], zoom + d));
		updateTiles();
		if(DEBUG) print("New Zoom: ", zoom);
	}

	var changeAlpha = func (d){
		alpha = math.max(0, math.min(1, alpha + d));
		window.setColorBackground(1,1,1, alpha);
	}

  # http://polymaps.org/docs/
  # https://github.com/simplegeo/polymaps
  # https://github.com/Leaflet/Leaflet

  var maps_base = getprop("/sim/fg-home") ~ '/cache/maps';

  # http://otile1.mqcdn.com/tiles/1.0.0/map
  # http://otile1.mqcdn.com/tiles/1.0.0/sat
  # (also see http://wiki.openstreetmap.org/wiki/Tile_usage_policy)
  # https://maps.wikimedia.org/osm-intl/${z}/${x}/${y}.png
  # http://a.tile.stamen.com/terrain/{z}/{x}/{y}.png

  foreach(var type; types) {
  	type.makeUrl = string.compileTemplate(type.urlTemplate);
  	type.makePath = string.compileTemplate(maps_base ~ type.urlPath);
  }

  var num_tiles = [4, 3];

  var center_tile_offset = [
  (num_tiles[0] - 1) / 2,
  (num_tiles[1] - 1) / 2
  ];

  # simple aircraft icon at current position/center of the map

  var filename = "Aircraft/R66/Instruments-3d/RenanGPSMap/svg/boeingAirplane.svg";
  var airplane_symbol = ui_root.createChild('group');
  canvas.parsesvg(airplane_symbol, filename);
  airplane_symbol.getElementById("path3783").setColor(1,0,0);

  airplane_symbol.setTranslation(width/2,height/2);
  #airplane_symbol.setTranslation(tile_size * center_tile_offset[0] - 10, tile_size * center_tile_offset[1]);

  airplane_symbol.setScale(.5);

  var filename = "Aircraft/R66/Instruments-3d/RenanGPSMap/svg/gpslayout.svg";
  var gpslayout = ui_root.createChild('group');
  canvas.parsesvg(gpslayout, filename);
  #gpslayout.getElementById("path3783").setColor(1,0,0);

  gpslayout.setTranslation(79,height - 79);
  gpslayout.setScale(.8);
  #gpslayout.setTranslation(tile_size * center_tile_offset[0] - 10, tile_size * center_tile_offset[1]);

  var tiles = setsize([], num_tiles[0]);
  for(var x = 0; x < num_tiles[0]; x += 1)
  {
  	tiles[x] = setsize([], num_tiles[1]);
  	for(var y = 0; y < num_tiles[1]; y += 1)
  	tiles[x][y] = g.createChild("image", "map-tile");
  }

  var last_tile = [-1,-1];
  var last_type = types[currentTypeID].type;

  ##
  # this is the callback that will be regularly called by the timer
  # to update the map
  var updateTiles = func()
  {
    if (getprop("/instrumentation/GPSMap/eletric") == 0) return; # not run if gps isnt ON

    # get current position
    var lat = getprop('/position/latitude-deg');
    var lon = getprop('/position/longitude-deg');

    # rotating airplane icon
    var DEG2RAD = 0.0174533;
    var hdg = getprop("/orientation/heading-deg") * DEG2RAD;
    var bearing = getprop("/instrumentation/gps/wp/wp[1]/bearing-true-deg");
    if (bearing == -9999) bearing = 0;
    bearing = bearing * DEG2RAD;
    var distance = getprop("/instrumentation/gps/wp/wp[1]/distance-nm");
    if (distance == -1) distance = ""; else distance = int(distance) ~ " NM";

    airplane_symbol.setRotation(hdg);
    gpslayout.getElementById("arrow").setRotation(bearing);
    gpslayout.getElementById("waypoint").setText(getprop("/instrumentation/gps/wp/wp[1]/ID"));
    gpslayout.getElementById("distance").setText(distance);
    gpslayout.getElementById("hdg").setText(int(getprop("/orientation/heading-deg")) ~ "");
    gpslayout.getElementById("coords").setText(getprop("/position/latitude-string") ~ " " ~ getprop("/position/longitude-string"));

    var n = math.pow(2, zoom);
    var offset = [
    n * ((lon + 180) / 360) - center_tile_offset[0],
    (1 - math.ln(math.tan(lat * math.pi/180) + 1 / math.cos(lat * math.pi/180)) / math.pi) / 2 * n - center_tile_offset[1]
    ];
    var tile_index = [int(offset[0]), int(offset[1])];

    var ox = tile_index[0] - offset[0];
    var oy = tile_index[1] - offset[1];

    for(var x = 0; x < num_tiles[0]; x += 1)
    for(var y = 0; y < num_tiles[1]; y += 1)
    tiles[x][y].setTranslation(int((ox + x) * tile_size + 0.5), int((oy + y) * tile_size + 0.5));

    if(    tile_index[0] != last_tile[0]
    	or tile_index[1] != last_tile[1]
    	or types[currentTypeID].type != last_type )
    {
    	for(var x = 0; x < num_tiles[0]; x += 1)
    	for(var y = 0; y < num_tiles[1]; y += 1)
    	{
    		var pos = {
    			z: zoom,
    			x: int(offset[0] + x),
    			y: int(offset[1] + y),
    			type: types[currentTypeID].type
    		};

    		(func {
    			var img_path = types[currentTypeID].makePath(pos);
    			var tile = tiles[x][y];

    			if( io.stat(img_path) == nil )
          { # image not found, save in $FG_HOME
          	var img_url = types[currentTypeID].makeUrl(pos);
          	if(DEBUG) print('requesting ' ~ img_url);
          	http.save(img_url, img_path)
          	.done(func {if(DEBUG) print('received image ' ~ img_path); tile.set("src", img_path);})
          	.fail(func (r) {if(DEBUG) print('Failed to get image ' ~ img_path ~ ' ' ~ r.status ~ ': ' ~ r.reason);})
          }
          else # cached image found, reusing
          {
          	if(DEBUG) print('loading ' ~ img_path);
          	tile.set("src", img_path)
          }
          })();
      }

      last_tile = tile_index;
      last_type = type;
  }
};

  ##
  # set up a timer that will invoke updateTiles at 2-second intervals
  var update_timer = maketimer(2, updateTiles);
  # actually start the timer
  update_timer.start();

  ##
  # set up default zoom level
  changeZoom(0);


  ###
  # The following lines were recently added and have not yet been tested
  # (if in doubt, remove them)
  window.del = func()
  {
  	print("Cleaning up window:", ,"\n");
  	update_timer.stop();
  # explanation for the call() technique at: http://wiki.flightgear.org/Object_oriented_programming_in_Nasal#Making_safer_base-class_calls
  call(canvas.Window.del, [], me);
};
return window;
}

var changeZoom = func(d)
{
	zoom = math.max(types[currentTypeID].minmaxzoom[0], math.min(types[currentTypeID].minmaxzoom[1], zoom + d));
	if(DEBUG) print("New Zoom: ", zoom);
}

var changeBright = func (d){
	bright = math.max(0, math.min(1, bright + d));
	setprop("/instrumentation/GPSMap/bright", bright);
}

var changeType = func (){
	if (currentTypeID == 0) currentTypeID = 1; else currentTypeID = 0;
	type = types[currentTypeID].type;
	if (zoom > types[currentTypeID].minmaxzoom[1]) zoom = types[currentTypeID].minmaxzoom[1];
	if (zoom < types[currentTypeID].minmaxzoom[0]) zoom = types[currentTypeID].minmaxzoom[0];
}

#--------------------------------------------------

var fdm_init_listener = _setlistener("/sim/signals/fdm-initialized", func {
	removelistener(fdm_init_listener);
	gps_map = show_map();
  setprop("/instrumentation/GPSMap/eletric", 0); # device off by default
  setprop("/instrumentation/GPSMap/bright", 1); # device off by default
  });