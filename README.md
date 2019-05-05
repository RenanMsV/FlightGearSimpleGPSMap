# FlightGearSimpleGPSMap
A simple 3D GPS instrument (aka tablet) for FlightGear Flight Simulator


![Example](https://i.imgur.com/EtT3CZI.jpg)

#### How to:
  Just include the file GPS.xml as a model in the aircraft's model xml
  
2 current providers: 

https://maps.wikimedia.org

![](https://maps.wikimedia.org/osm-intl/2/2/1.png)

and

http://a.tile.stamen.com

![](http://a.tile.stamen.com/terrain/2/2/1.png)

you can add more providers by adding em to the 'types' array

```nasal
var types = [
	...other types,
	{
		minmaxzoom : [2,14],
		type : "example-type",
		urlTemplate : "http://example-url.com/{type}/{z}/{x}/{y}.png",
		urlPath : "/{type}/{z}/{x}/{y}.png"
	}
];
```
