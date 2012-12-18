// 
//  AudioRenderer.pde
//  Ilias Karim
//  Music 250A, CCRMA, Stanford University
//

// abstract class for audio visualization
// via http://www.openprocessing.org/sketch/5989
abstract class AudioRenderer implements AudioListener {
  float[] left;
  float[] right;
  synchronized void samples(float[] samp) { left = samp; }
  synchronized void samples(float[] sampL, float[] sampR) { left = sampL; right = sampR; }
  //abstract void setup();
  abstract void draw(); 
}
