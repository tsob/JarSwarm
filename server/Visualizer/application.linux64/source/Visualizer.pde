//
//  Visualizer
//  Ilias Karim
//  Music 250A, CCRMA, Stanford University
//

//import processing.core.PGraphics3D;
//import processing.core.*;
//import processing.opengl.*;

import oscP5.*;
import netP5.*;
import ddf.minim.*;

int oscPort = 57121;

// numbers of boids and attractors are hard-coded in GridRenderer :(
//float[][] boids = new float[16][2]; // doubly hard-coded in GridRenderer
//float[][] attractors = new float[9][2];

OscP5 oscP5;// = new OscP5(this, oscPort);
Minim minim = new Minim(this);
AudioSource source;
GridRenderer gridRenderer;
int select;
 
void setup()
{
  oscP5 = new OscP5(this, oscPort);

  size(1024, 708);
    
  //minim = new Minim(this);
  source = minim.getLineIn(); 
  
  gridRenderer = new GridRenderer(source);
 
  source.addListener(gridRenderer);
}
 
void draw()
{
  gridRenderer.draw();
}
 

void oscEvent(OscMessage msg) 
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
    float rVal = msg.get(0).intValue() / 128.;
    float gVal = msg.get(1).intValue() / 128.;
    float bVal = msg.get(2).intValue() / 128.;
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
    int i = int(msg.get(0).intValue());
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

void stop()
{
  source.close();
  minim.stop();
  super.stop();
}


