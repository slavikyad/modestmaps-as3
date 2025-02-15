package com.modestmaps.mapproviders
{

	import com.modestmaps.core.Coordinate;
	
	/**
	 * @author migurski
	 * $Id$
	 */
	
	public class AbstractZoomifyMapProvider extends AbstractMapProvider implements IMapProvider
	{
	    private var __baseDirectory:String;
	    private var __groups:/*Coordinate*/Array;


		//variables from original zoomify class TileCache.as
		private var widthScale:Number;
		private var heightScale:Number;
		private var limitsArray:Array;
		//-------------------------------------------------

	
	    public function AbstractZoomifyMapProvider()
        {
            super();
	        
	       /*
	        * Example sub-class constructor:
	        *
	        *   public function MyZoomifyMapProvider()
	        *   {
	        *       super();
	        *
	        *       // defineImageProperties() *must* be called!
	        *       defineImageProperties('http://example.com/', 256, 256);
	        *
	        *       // Calculate the transformation and projectionbased on chosen markers.  
	        *       // See http://modestmaps.com/calculator.html
	        *       var t:Transformation = new Transformation(1, 0, 0, 0, 1, 0);
	        *       __projection = new LinearProjection(0, t);
	        *   }
	        *
	        */
	    }
	
	    public function toString():String
	    {
	        return "ABSTRACT_ZOOMIFY";
	    }
	
	   /**
	    * Zoomifyer EZ (download: http://www.zoomify.com/express.htm) cuts a base
	    * image into tiles, and creates a metadata file named ImageProperties.xml
	    * in the same directory. Instead of parsing that file, pass the relevant
	    * bits to this method. Base directory *must* have a trailing slash.
	    *
	    * Example:
	    *
	    *   ImageProperties.xml content:
	    *       <IMAGE_PROPERTIES WIDTH="11258" HEIGHT="7085" NUMTILES="1650" NUMIMAGES="1" VERSION="1.8" TILESIZE="256" />
	    *
	    *   URL of ImageProperties.xml:
	    *       http://example.com/ImageProperties.xml
	    *
	    *   Corresponding call to defineImageProperties():
	    *       defineImageProperties('http://example.com/', 11258, 7085);
	    *
	    * Tiles created by Zoomifyer EZ are placed in folders named "TileGroup{0..n}",
	    * in groups of 256, so we need to quickly iterate through the entire set of
	    * tile coordinates to determine where the group boundaries are. These are
	    * stored in the __groups array.
	    */
		protected function defineImageProperties(baseDirectory:String, width:Number, height:Number):void
		{
	        __baseDirectory = baseDirectory;
	
	        var zoom:Number = Math.ceil(Math.log(Math.max(width, height)) / Math.LN2);
	
	        __topLeftOutLimit = new Coordinate(0, 0, 0);
	        __bottomRightInLimit = (new Coordinate(height, width, zoom)).zoomTo(zoom - 8);
	
	        __groups = [];

			calculatePathLimits(256, width, height);

	        var i:Number = 0;
	        
	       /*
	        * Iterate over all possible tiles in order: left to right, top to
	        * bottom, zoomed-out to zoomed-in. Note the first tile coordinate
	        * in each group of 256.
	        */
	        for(var c:Coordinate = __topLeftOutLimit.copy(); c.zoom <= __bottomRightInLimit.zoom; c.zoom += 1) {
	            
	            // edges of the image at current zoom level
	            var tlo:Coordinate = __topLeftOutLimit.zoomTo(c.zoom);
	            var bri:Coordinate = __bottomRightInLimit.zoomTo(c.zoom);
	        
	            // left-to-right, top-to-bottom, like reading a book
	            for(c.row = tlo.row; c.row <= bri.row; c.row += 1) {
	                for(c.column = tlo.column; c.column <= bri.column; c.column += 1) {
	                
	                    // zoomify groups tiles into folders of 256 each
	                    if(i % 256 == 0)
	                        __groups.push(c.copy());
	                    
	                    i += 1;
	                }
	            }   
	        }
			trace(__groups);
	    }
	    
	    private function coordinateGroup(c:Coordinate):Number
	    {
			var offset:Number = c.row * Math.ceil((1 << c.zoom) * widthScale) + c.column;
			for(var i:uint = 0; i < c.zoom; i++) { offset += limitsArray[i]; }
			return Math.floor(offset / 256);
	    }
	
	    public function getTileUrls(coord:Coordinate):Array
	    {
			return [ __baseDirectory+'TileGroup'+coordinateGroup(coord)+'/'+(coord.zoom)+'-'+(coord.column)+'-'+(coord.row)+'.jpg' ];
	    }


		//this is better way to calculate TileGroup
		
		private function calculatePathLimits(tileSize:uint, fullWidth:uint, fullHeight:uint):void 
		{
			var max:Number = Math.max(fullWidth, fullHeight ) / Number(tileSize);
			for (var i:uint = 0; (1 << i) < max; i++) 
			{
				widthScale = fullWidth / ((1 << i) * tileSize);
				heightScale = fullHeight / ((1 << i) * tileSize);
				if(max > (1 << i)) { widthScale = fullWidth / ((1 << (i + 1)) * tileSize); }
				if(max > (1 << i)) { heightScale = fullHeight / ((1 << (i + 1)) * tileSize); }
			}
			limitsArray = [];
			for (var t:uint = 0; t <= i; t++) 
			{
				var tileNumber:uint = 0;
				var n:uint = 1 << t;
				limitsArray.push(Math.ceil(widthScale * n) * Math.ceil(heightScale * n));
			}
		}
	}
	
}
