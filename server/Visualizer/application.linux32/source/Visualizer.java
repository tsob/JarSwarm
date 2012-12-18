import processing.core.*; 
import processing.data.*; 
import processing.opengl.*; 

import oscP5.*; 
import netP5.*; 
import ddf.minim.*; 

import org.tritonus.share.midi.*; 
import org.tritonus.sampled.file.*; 
import javazoom.jl.player.advanced.*; 
import org.tritonus.share.*; 
import ddf.minim.*; 
import ddf.minim.analysis.*; 
import netP5.*; 
import org.tritonus.share.sampled.*; 
import javazoom.jl.converter.*; 
import javazoom.spi.mpeg.sampled.file.tag.*; 
import org.tritonus.share.sampled.file.*; 
import javazoom.spi.mpeg.sampled.convert.*; 
import ddf.minim.javasound.*; 
import oscP5.*; 
import javazoom.spi.*; 
import org.tritonus.share.sampled.mixer.*; 
import javazoom.jl.decoder.*; 
import processing.xml.*; 
import processing.core.*; 
import org.tritonus.share.sampled.convert.*; 
import ddf.minim.spi.*; 
import ddf.minim.effects.*; 
import javazoom.spi.mpeg.sampled.file.*; 
import ddf.minim.signals.*; 
import javazoom.jl.player.*; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class Visualizer extends PApplet {

//
//  Visualizer
//  Ilias Karim
//  Music 250A, CCRMA, Stanford University
//

//import processing.core.PGraphics3D;
//import processing.core.*;
//import processing.opengl.*;





int oscPort = 57121;

// numbers of boids and attractors are hard-coded in GridRenderer :(
//float[][] boids = new float[16][2]; // doubly hard-coded in GridRenderer
//float[][] attractors = new float[9][2];

OscP5 oscP5;// = new OscP5(this, oscPort);
Minim minim = new Minim(this);
AudioSource source;
GridRenderer gridRenderer;
int select;
 
public void setup()
{
  oscP5 = new OscP5(this, oscPort);

  size(1024, 708);
    
  //minim = new Minim(this);
  source = minim.getLineIn(); 
  
  gridRenderer = new GridRenderer(source);
 
  source.addListener(gridRenderer);
}
 
public void draw()
{
  gridRenderer.draw();
}
 

public void oscEvent(OscMessage msg) 
{  
  String pattern = msg.addrPattern();
  
  //
  // parse visualization control messages from PD
  //
  if (pattern.equals("/radius")) {
    int val = msg.get(0).intValue();
    gridRenderer.r = val;
  }
  
  else if (pattern.equals("/rgb")) {
    float rVal = msg.get(0).intValue() / 128.f;
    float gVal = msg.get(1).intValue() / 128.f;
    float bVal = msg.get(2).intValue() / 128.f;
    gridRenderer.setRGB(rVal, gVal, bVal);
  }
  
  else if (pattern.equals("/intensity")) {
    gridRenderer.alpha = msg.get(0).floatValue();
  }
  
  else if (pattern.equals("/mode")) {
    gridRenderer.setMode(msg.get(0).intValue());
  }
  
  // 
  // parse ... control messages from Python
  //
  else if (pattern.equals("/boid")) {
    int i = PApplet.parseInt(msg.get(0).intValue());
    print("\n" + i + "\n");
    gridRenderer.boids[i][0] = msg.get(1).floatValue();
    gridRenderer.boids[i][1] = msg.get(2).floatValue();
    //gridRenderer.boids = boids;
  }
  
  /*
  else if (pattern.equals("/attractor")) {
    attractors[msg.get(0).intValue()][0] = msg.get(1).floatValue();
    attractors[msg.get(0).intValue()][1] = msg.get(1).floatValue();
  }*/
  
  // debug
  //print(msg);
}

public void stop()
{
  source.close();
  minim.stop();
  super.stop();
}



/// abstract class for audio visualization
abstract class AudioRenderer implements AudioListener {
  float[] left;
  float[] right;
  public synchronized void samples(float[] samp) { left = samp; }
  public synchronized void samples(float[] sampL, float[] sampR) { left = sampL; right = sampR; }
  public abstract void setup();
  public abstract void draw(); 
}

// abstract class for FFT visualization
abstract class FourierRenderer extends AudioRenderer {
  FFT fft;
  float maxFFT;
  float[] leftFFT;
  float[] rightFFT;
  
  FourierRenderer(AudioSource source) {
    float gain = .1f;
    fft = new FFT(source.bufferSize(), source.sampleRate());
    maxFFT =  source.sampleRate() / source.bufferSize() * gain;
    fft.window(FFT.HAMMING);
  }
  
  public void calc(int bands) {
    if(left != null) {
      leftFFT = new float[bands];
      fft.linAverages(bands);
      fft.forward(left);
      for(int i = 0; i < bands; i++) leftFFT[i] = fft.getAvg(i);   
    }
  }
}




class GridRenderer extends FourierRenderer 
{
  int SquareMode = 1;
  int DiamondMode = 0;
    
  float[][] boids = new float[19][2];
  
  // radius
  int r = 20;
  // "squeeze" 
  float squeeze = .5f;
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

  public void setup() 
  { 
    colorMode(RGB, colorScale, colorScale, colorScale);
    //setRGB(1, 1, 1);
  } 

  int mode;
  
  public void setMode(int myMode)
  {
    mode = myMode;

    print("setMode: " + mode + "\n");
  }

  // color
  float rgb[] = { 1, 1, 1 };
  float _rgb[] = { 0, 0, 0 };
  public void setRGB(float r, float g, float b)
  {
    rgb[0] = r;
    rgb[1] = g;
    rgb[2] = b;
    
    print("set RGB: (" + r + ", " + g + ", " + b + ")\n"); 
  }


  float diamondTileAlpha = 0;

  float alpha = 1;
  float _alpha = 1;
  
  public void draw() 
  {
    if (left != null) {
      
      val = new float[ceil(sqrt(2) * r)];   
      super.calc(val.length);

      // interpolate values
      for (int i=0; i<val.length; i++) { 
        val[i] = lerp(val[i], pow(leftFFT[i], squeeze), .1f);
      }

      background(0);

      float tileWidth = width / (2*r + 1);
      float tileHeight = height / (2*r + 1);


      if (mode == 0) {
        if (factor < 2) {
          factor += .04f;
        }
        else {
          factor = 2;
        }

        if (diamondTileAlpha < 1) {  
          diamondTileAlpha += .02f;
        }
      }
      else {
        if (diamondTileAlpha > 0) {
          diamondTileAlpha -= .02f;
        }
        else if (factor > 1) {
          factor -= .04f;
        }
        else
        {
          factor = 1;
        }
      }      
      
      _rgb[0] = lerp(_rgb[0], rgb[0], .01f);
      _rgb[1] = lerp(_rgb[1], rgb[1], .01f);
      _rgb[2] = lerp(_rgb[2], rgb[2], .01f);
      
      _alpha = lerp(_alpha, alpha, .1f);
      
      for (int x = -r; x < r + 2; x++) { 
        for (int z = -r; z < r + 2; z++) {   

          int index = (int)dist(x, z, 0, 0);
          if (index >= val.length)
            index = val.length - 1;
          float c = 256 * val[index];

          fill(c * _rgb[0] * _alpha, c * _rgb[1] * _alpha, c * _rgb[2] * _alpha);

          float x0 = width / 2 + (tileWidth * (x - .5f));
          float x1 = x0 + tileWidth;
          float y0 = height / 2 + (tileHeight * (z - .5f));
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

             if ((int)((boids[i][0] -.5f) * r * 2) == x && (int)((boids[i][1] - .5f) * r * 2) == z) {
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

  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "--full-screen", "--bgcolor=#666666", "--hide-stop", "Visualizer" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
