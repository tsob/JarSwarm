

class GridRenderer extends FourierRenderer 
{
  int SquareMode = 1;
  int DiamondMode = 0;
    
  float[][] boids = new float[19][2];
  
  // radius
  int r = 20;
  // "squeeze" 
  float squeeze = .5;
  // color scale
  float colorScale = 40;

  float val[];

  float factor = 1;
  float factorAlpha = 0;

  GridRenderer(AudioSource source) 
  {
    super(source);
    //val = new float[ceil(sqrt(2) * r)];
  }

  void setup() 
  { 
    colorMode(RGB, colorScale, colorScale, colorScale);
    //setRGB(1, 1, 1);
  } 

  int mode;
  
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


  float diamondTileAlpha = 0;

  float alpha = 1;
  float _alpha = 1;
  
  void draw() 
  {
    if (left != null) {
      
      val = new float[ceil(sqrt(2) * r)];   
      super.calc(val.length);

      // interpolate values
      for (int i=0; i<val.length; i++) { 
        val[i] = lerp(val[i], pow(leftFFT[i], squeeze), .1);
      }

      background(0);

      float tileWidth = width / (2*r + 1);
      float tileHeight = height / (2*r + 1);


      if (mode == 0) {
        if (factor < 2) {
          factor += .04;
        }
        else {
          factor = 2;
        }

        if (diamondTileAlpha < 1) {  
          diamondTileAlpha += .02;
        }
      }
      else {
        if (diamondTileAlpha > 0) {
          diamondTileAlpha -= .02;
        }
        else if (factor > 1) {
          factor -= .04;
        }
        else
        {
          factor = 1;
        }
      }      
      
      _rgb[0] = lerp(_rgb[0], rgb[0], .01);
      _rgb[1] = lerp(_rgb[1], rgb[1], .01);
      _rgb[2] = lerp(_rgb[2], rgb[2], .01);
      
      _alpha = lerp(_alpha, alpha, .1);
      
      for (int x = -r; x < r + 2; x++) { 
        for (int z = -r; z < r + 2; z++) {   

          int index = (int)dist(x, z, 0, 0);
          if (index >= val.length)
            index = val.length - 1;
          float c = 256 * val[index];

          fill(c * _rgb[0] * _alpha, c * _rgb[1] * _alpha, c * _rgb[2] * _alpha);

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

           c = 256 * val[(int)avg] * diamondTileAlpha; 
           
           float bonus = 1;
           
           /*
           if (random(0, 100) > 99)
             bonus = random(1, 2);
           */
           
           fill(c * _rgb[0] * _alpha * bonus, c * _rgb[1] * _alpha * bonus, c * _rgb[2] * _alpha * bonus);
         
           //fill(1, 1, 1, 0);
         
           for (int i = 0; i < 19; i++) {

             if ((int)((boids[i][0] -.5) * r * 2) == x && (int)((boids[i][1] - .5) * r * 2) == z) {
               //print ((boids[i][0] * width) + " " + (boids[i][1] * height) + "\n");
              
               fill(256, 256, 256, 256);
               //print("EUREKA");
             }
           }

          quad(x0 + tileWidth / factor, y0, 
          x0, y1 - tileHeight / factor, 
          x1 - tileWidth / factor, y1, 
          x1, y0 + tileHeight / factor);          

          if (factor == 2)
            // diamond
            quad(x0 + tileWidth / factor + tileWidth / factor, y0 + tileHeight / factor, 
            x0 + tileWidth / factor, y1 - tileHeight / factor + tileHeight / factor, 
            x1 - tileWidth / factor + tileWidth / factor, y1 + tileHeight / factor, 
            x1 + tileWidth / factor, y0 + tileHeight / factor + tileHeight / factor);
        }
      }
    }
  }
}

