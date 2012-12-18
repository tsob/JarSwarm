//
//  Visualizer.pde
//  Ilias Karim
//  Music 250A, CCRMA, Stanford University
//

import oscP5.*;
import netP5.*;
import ddf.minim.*;

// incoming OSC port for swarm.py
static final int oscPort = 57121;
// NOTE: numbers of boids are hard-coded in GridRenderer :(

OscP5 oscP5;
Minim minim;
Random random;
AudioSource source;
GridRenderer gridRenderer;
int select;
 
boolean sketchFullScreen() {
  return false;
}

void setup()
{
  oscP5 = new OscP5(this, oscPort);

  size(1920, 1080);
    
  random = new Random();
   
  minim = new Minim(this);
  AudioSource source = minim.getLineIn(); 
  
  gridRenderer = new GridRenderer(source);
  
  source.addListener(gridRenderer);
}
 
void draw()
{
  gridRenderer.draw();
}
 

void oscEvent(OscMessage msg) 
{  
  // debug
  print(msg);

  String pattern = msg.addrPattern();
    
  // handle OSC messages from SuperCollider
  if (pattern.equals("/jerk")) {
    // toggle mode
    gridRenderer.setMode(gridRenderer.mode == 0 ? 1 : 0);
    //gridRenderer.setMode(random.nextInt() % 2);
        
    // semi-random color
    int colorMode = random.nextInt() % 7;
    if (colorMode == 0) {
     gridRenderer.setRGB(1, 140./255, 0); // orange
    } else if (colorMode == 1) { 
      gridRenderer.setRGB(1, 1, 0); // brown
    } else if (colorMode == 2) {
      gridRenderer.setRGB(1, 0, 1); // purple
    } else if (colorMode == 3) {
      gridRenderer.setRGB(0, 1, 1); // yellow
    } else if (colorMode == 4) {
      gridRenderer.setRGB(1, 0, 0); // red
    } else if (colorMode == 5) {
      gridRenderer.setRGB(0, 1, 0); // green
    } else if (colorMode == 6) {
      gridRenderer.setRGB(0, 0, 1); // blue
    }
    
    // random radius
    gridRenderer.r = (random.nextInt() % 5 + 20);
  }
  
  else if (pattern.equals("/ioi")) {
    print("ioi");
  }
  else if (pattern.equals("/on")) {
    print("on");
  }
 
  else if (pattern.equals("/off")) {
    print("off");
  } 
   
  // handle OSC messages from swarm.py
  else if (pattern.equals("/boid")) {
    int i = int(msg.get(0).intValue());
    //print("\n" + i + "\n");
    gridRenderer.boids[i][0] = msg.get(1).floatValue();
    gridRenderer.boids[i][1] = msg.get(2).floatValue();
    //gridRenderer.boids = boids;
  }  
  
  /*
  // handle OSC messages from PD
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
    gridRenderer._alpha = msg.get(0).floatValue();
  }
  
  else if (pattern.equals("/mode")) {
    gridRenderer.setMode(msg.get(0).intValue());
  }*/
}

void stop()
{
  source.close();
  minim.stop();
  super.stop();
}


