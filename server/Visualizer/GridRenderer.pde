// 
//  GridRenderer.pde
//  Ilias Karim
//  Music 250A, CCRMA, Stanford University
//

// GridRender with square and diamond modes, based on isometric renderer
// via http://www.openprocessing.org/sketch/5989 via http://www.openprocessing.org/sketch/5671
class GridRenderer extends FourierRenderer 
{
  int SquareMode = 1;
  int DiamondMode = 0;
    
  float[][] boids = new float[19][2];
  float[][] boids2 = new float[19][2];
  float[][] boids3 = new float[19][2];

  
  // radius
  float r = 20;
  float _r = 20;

  // color scale
  float colorScale = 40;

  float val[];

  float factor = 1;
  float diamondTileAlpha = 0;

  GridRenderer(AudioSource source) 
  {
    super(source);
  }

  int mode = 1;
  
  void setMode(int myMode)
  {
    mode = myMode;

    print("setMode: " + mode + "\n");
  }

  // color
  float rgb[] = { 1, 1, 1 };
  float _rgb[] = { 0, 0, 0 };
  void setRGB(float r, float g, float b)
  {
    rgb[0] = r;
    rgb[1] = g;
    rgb[2] = b;
    
    print("set RGB: (" + r + ", " + g + ", " + b + ")\n"); 
  }


  // intensity factor
  float _intensity = 2;
  
  // "squeeze" 
  float squeeze = .7;
  
  void draw() 
  {
    if (left != null) {
      
      val = new float[ceil(sqrt(2) * (int)_r)];   
      super.calc(val.length);

      // interpolate values
      for (int i=0; i<val.length; i++) { 
        val[i] = lerp(val[i], pow(leftFFT[i], squeeze), .3);
      }

      background(0);

      float tileWidth = width / (2*_r + 1);
      float tileHeight = height / (2*_r + 1);

      _r = lerp(_r, r, .1);
      //print(_r + "\n");
      
      if (mode == 0) {
        factor = lerp(factor, 2, .2);
        diamondTileAlpha = lerp(diamondTileAlpha, 1, .02);
      }
      else {
        diamondTileAlpha = lerp(diamondTileAlpha, 0, .02);
        factor = lerp(factor, 1, .2);
      }      
      
      _rgb[0] = lerp(_rgb[0], rgb[0], .01);
      _rgb[1] = lerp(_rgb[1], rgb[1], .01);
      _rgb[2] = lerp(_rgb[2], rgb[2], .01);
      
      for (int x = (int)-_r; x < _r + 2; x++) { 
        for (int z = (int)-_r; z < _r + 2; z++) {   
          int index = (int)dist(x, z, 0, 0);
          if (index >= val.length)
            index = val.length - 1;
          float c = 256 * val[index];

          float x0 = width / 2 + (tileWidth * (x - .5));
          float x1 = x0 + tileWidth;
          float y0 = height / 2 + (tileHeight * (z - .5));
          float y1 = y0 + tileHeight;

          x0 -= tileWidth / 2;
          x1 -= tileWidth / 2;
          y0 -= tileHeight / 2;
          y1 -= tileHeight / 2;

          float avg;
          
          avg = (dist(x, z, 0, 0) + dist(x, z + 1, 0, 0) + dist(x + 1, z, 0, 0) + dist(x + 1, z + 1, 0, 0)) / 4;
           
          if (avg >= val.length)
            avg = val.length - 1;

          c = 256 * val[(int)avg] * _intensity; 
           
          fill(c * _rgb[0], c * _rgb[1], c * _rgb[2]);

          for (int i = 0; i < 19; i++) {
            if ((x > -_r + 1 || z > -_r + 1) && (int)((boids[i][0] -.5) * _r * 2) == x && (int)((boids[i][1] - .5) * _r * 2) == z) {
              fill(pow(c * _rgb[0] * _intensity, 1.5), pow(c * _rgb[1] * _intensity, 1.5), pow(c * _rgb[2] * _intensity, 1.5));
            }
            
            /*
            float xDist = abs(((boids[i][0] -.5) * r * 2) - x);
            float zDist = abs(((boids[i][1] - .5) * r * 2) - z);
            float distance = dist(xDist, zDist, 0, 0);
            
            if (distance < 1) {
              float colorFactor = pow(distance, 4) * 2;
              fill(pow(c * _rgb[0] * _intensity, colorFactor), pow(c * _rgb[1] * _intensity, colorFactor), pow(c * _rgb[2] * _intensity, colorFactor));
            }
            */
          }

          quad(x0 + tileWidth / factor, y0, 
               x0, y1 - tileHeight / factor, 
               x1 - tileWidth / factor, y1, 
               x1, y0 + tileHeight / factor);          

          if (factor > 1.7) {
            quad(x0 + tileWidth / factor + tileWidth / factor, y0 + tileHeight / factor, 
                 x0 + tileWidth / factor, y1 - tileHeight / factor + tileHeight / factor, 
                 x1 - tileWidth / factor + tileWidth / factor, y1 + tileHeight / factor, 
                 x1 + tileWidth / factor, y0 + tileHeight / factor + tileHeight / factor);
          }
        }
      }
    }
  }
}
