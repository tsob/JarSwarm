
// abstract class for FFT visualization
abstract class FourierRenderer extends AudioRenderer {
  FFT fft;
  float maxFFT;
  float[] leftFFT;
  float[] rightFFT;
  
  FourierRenderer(AudioSource source) {
    float gain = .1;
    fft = new FFT(source.bufferSize(), source.sampleRate());
    maxFFT =  source.sampleRate() / source.bufferSize() * gain;
    fft.window(FFT.HAMMING);
  }
  
  void calc(int bands) {
    if(left != null) {
      leftFFT = new float[bands];
      fft.linAverages(bands);
      fft.forward(left);
      for(int i = 0; i < bands; i++) leftFFT[i] = fft.getAvg(i);   
    }
  }
}


