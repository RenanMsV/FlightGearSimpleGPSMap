# FlightGearSimpleGPSMap
A simple 3D GPS instrument (aka tablet) for FlightGear Flight Simulator


![Example](https://i.imgur.com/EtT3CZI.jpg)

#### How to:
  Just include the file GPS.xml as a model in the aircraft's model xml, example:
  ```xml
  <model>
    <path>Aircraft/737/Models/FlightGearSimpleGPSMap/GPS.xml</path>
	<offsets>
      <x-m>0.0</x-m>
      <y-m>0.0</y-m>
      <z-m>0.0</z-m>
    </offsets>
  </model>
  ```

  and then include the nasal script at the aircraft's -set file, example:

  ```xml
  <nasal>
	<gps>
      <file>Aircraft/Mil-Mi-8/Models/Interior/Cockpit/FlightGearSimpleGPSMap/GPS.nas</file>
    </gps>
  </nasal>
  ```
  <sup>Make sure to include it inside a `<gps>` tag or the buttons wont work.</sup>
  
2 current providers: 

https://maps.wikimedia.org

![](https://maps.wikimedia.org/osm-intl/2/2/1.png)

and

http://a.tile.stamen.com

![](http://a.tile.stamen.com/terrain/2/2/1.png)

you can add more providers by adding em to the 'types' array inside the `GPS.nas` file, you just need to know the correct url pattern

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

#### How to change the 3D model

You can easily change the 3D model, just make sure to keep all button names and the screen name as they are, do not change them.
