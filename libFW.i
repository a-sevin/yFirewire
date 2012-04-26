plug_in,"libFW";

func setupCam(expo, gain, speed=) {
/* DOCUMENT 
     [sizex, sizey] = setupCam(expo, gain, speed);
     
     Setup the camera with the exposure (don't use the extended shutter) ant the gain
     speed = 400 or 800
     
   SEE ALSO: unsetupCam, startCam, stopCam, listFeatures
 */
  extern sizex, sizey;
  if ( is_void(sizex) ) sizex = 0;
  if ( is_void(sizey) ) sizey = 0;
  if ( is_void(expo)  ) expo  = 100;
  if ( is_void(gain)  ) gain  = 380;
  if ( is_void(speed)  ) speed  = 400;
  _setupCam, expo, gain, &sizex, &sizey, speed;
  write, format="sizex=%d sizey=%d\n", sizex, sizey;
  return [sizex, sizey];
}
extern _setupCam
/* PROTOTYPE
   int _setupCam(long expo, long gain, pointer sizex, pointer sizey, long speed)
*/

func unsetupCam(void) {
/* DOCUMENT 
      unsetupCam;
      
      free the camera
      
   SEE ALSO: setupCam, startCam, stopCam, listFeatures
 */
  return _unsetupCam();
}
extern _unsetupCam
/* PROTOTYPE
   int _unsetupCam(void)
*/

func listFeatures(void) {
/* DOCUMENT 
     listFeatures;

     list features supported by the camera
     
   SEE ALSO:
 */
  return _listFeatures();
}
extern _listFeatures
/* PROTOTYPE
   int _listFeatures( void )
*/

func startCam(void) {
/* DOCUMENT 
     startCam;
     
     Setup the camera for aquisition. For Now, the camera is startig to send us data
     
   SEE ALSO: setupCam, unsetupCam, stopCam, listFeatures
 */
  return _startCam();
}
extern _startCam
/* PROTOTYPE
   int _startCam(void)
*/

func stopCam(void) {
/* DOCUMENT 
     startCam;
     
     Setup the camera for stop the aquisition.
     
   SEE ALSO: setupCam, unsetupCam, startCam, listFeatures
 */
  return _stopCam();
}
extern _stopCam
/* PROTOTYPE
   int _stopCam(void)
*/

func setVideoMode( mode ){
/* DOCUMENT 
     setVideoMode, mode
     [sizex, sizey] = setVideoMode( mode );

     Switch between acquisition mode
     modes are :
      - 0 : no binning
      - 1 : binning 8x8
      - 2 : binning 4x4
      - 3 : binning 2x2
      
   SEE ALSO:
 */
  extern sizex, sizey;
  if ( is_void(sizex) ) sizex = 0;
  if ( is_void(sizey) ) sizey = 0;
  _setVideoMode, mode,  &sizex, &sizey;
  write, format="sizex=%d sizey=%d\n", sizex, sizey;
  return [sizex, sizey];
}
extern _setVideoMode
/* PROTOTYPE
   int _setVideoMode(int mode, pointer ySizeX, pointer ySizeY)
*/

func getBinning( void ){
/* DOCUMENT
     [binx, biny] = getBinning( );

     ??? no idea of what is called "binning" no changes with video mode
     
   SEE ALSO:
 */
  binx=biny=0;
  _getBinning, &binx, &biny;
  return [binx, biny];
}
extern _getBinning
/* PROTOTYPE
   int _getBinning(pointer ySizeX, pointer ySizeY)
*/

func getMaxRes( void ){
/* DOCUMENT 
     [resx, resy] = getMaxRes( );

     It gives you the size of the captor
     
   SEE ALSO:
 */
  resx=resy=0;
  _getMaxRes, &resx, &resy;
  return [resx, resy]
}
extern _getMaxRes
/* PROTOTYPE
   int _getMaxRes(pointer ySizeX, pointer ySizeY)
*/

func setROI( yX, yY, ySizeX, ySizeY){
/* DOCUMENT 
     setROI( yX, yY, ySizeX, ySizeY);

     define the region of interess to read
     
   SEE ALSO:
 */
  return _setROI( yX, yY, ySizeX, ySizeY );
}
extern _setROI
/* PROTOTYPE
   int _setROI(long yX, long yY, long ySizeX, long ySizeY)
*/

func getROI( void ){
/* DOCUMENT 
     [yX,yY,ySizeX,ySizeY] = getROI( );

     Return the size of the region on interess
     
   SEE ALSO:
 */
  yX=yY=ySizeX=ySizeY=0
  _getROI, &yX, &yY, &ySizeX, &ySizeY;
  return [yX,yY,ySizeX,ySizeY]
}
extern _getROI
/* PROTOTYPE
   int _getROI(pointer yX, pointer yY, pointer ySizeX, pointer ySizeY)
*/

func setGain( Gain ){
/* DOCUMENT 
     setGain, gain;

     define the gain of the camera
     
   SEE ALSO:
 */
  return _setGain ( Gain );
}
extern _setGain
/* PROTOTYPE
   int _setGain(long yGain)
*/

func getGain( void ){
/* DOCUMENT 
     gain = getGain();

     return the gain of the camera
     
   SEE ALSO:
 */
  return _getGain();
}
extern _getGain
/* PROTOTYPE
   int _getGain( void )
*/

func setExpo( expo ){
/* DOCUMENT 
     setExpo, expo;

     define the exposure of the camera using DC1394_FEATURE_SHUTTER feature
     
   SEE ALSO:
 */
  return _setExpo( expo );
}
extern _setExpo
/* PROTOTYPE
   int _setExpo(long yExpo)
*/

func getExpo( void ){
/* DOCUMENT 
     expo = getExpo();

     return the exposure of the camera using DC1394_FEATURE_SHUTTER feature

   SEE ALSO:
 */
  return _getExpo();
}
extern _getExpo
/* PROTOTYPE
   int _getExpo(void)
*/

func setExposure( expo ){
/* DOCUMENT 
     setExposure, expo;

     define the exposure of the camera using DC1394_FEATURE_EXPOSURE feature
     
   SEE ALSO:
 */
  return _setExposure( expo );
}
extern _setExposure
/* PROTOTYPE
   int _setExposure(long yExpo)
*/

func getExposure( void ){
/* DOCUMENT 
     expo = getExposure();

     return the exposure of the camera using DC1394_FEATURE_EXPOSURE feature

   SEE ALSO:
 */
  return _getExposure();
}
extern _getExposure
/* PROTOTYPE
   int _getExposure(void)
*/

func setOffset( offset ){
/* DOCUMENT 
     setOffset, offset;

     define the offset of the camera using DC1394_FEATURE_BRIGHTNESS feature
     
   SEE ALSO:
 */
  return _setOffset( offset );
}
extern _setOffset
/* PROTOTYPE
   int _setOffset(long offset)
*/

func getOffset( void ){
/* DOCUMENT 
     offset = getOffset();

     return the exposure of the camera using DC1394_FEATURE_BRIGHTNESS feature

   SEE ALSO:
 */
  return _getOffset();
}
extern _getOffset
/* PROTOTYPE
   int _getOffset(void)
*/

func setExtShut( expo ){
/* DOCUMENT 
     setExtShut, expo;

     define the extented shutter time in microseconds of the camera

   SEE ALSO:
 */
  return _setExtShut( expo );
}
extern _setExtShut
/* PROTOTYPE
   int _setExtShut(long yExpo)
*/

func getExtShut( void ){
/* DOCUMENT 
     expo = getExtShut();

     return the extented shutter time in microseconds of the camera

   SEE ALSO:
 */
  return _getExtShut();
}
extern _getExtShut
/* PROTOTYPE
   int _getExtShut(void)
*/

func acquire(nbframes) {
/* DOCUMENT 
     img = acquire(nbframes);

     setup the camera for acquisition then acquire nbframes images and stop the acquisition

   SEE ALSO: startCam, stopCam
 */
  if(startCam()) return;
  if ( is_void(nbframes) ) nbframes  = 1;
  yX=yY=sizex=sizey=0
  _getROI, &yX, &yY, &sizex, &sizey;
  img=array(short(0), sizex, sizey, nbframes);
  tic; _acquire, &img, sizex, sizey, nbframes; tac();
  stopCam;
  img=int(img);
  ind = where(img<0);
  if(is_array(ind)) img(ind) += 65536;
  if(nbframes == 1)
    img = img(,,1);
  return img;
}
extern _acquire
/* PROTOTYPE
   int _acquire( pointer yFrames, long sizex, long sizey, long nbframes )
*/
rtd_stop=1;
func rtd_loop( freq ) {
  extern sizex, sizey, rtd_img, rtd_freq;
  if(rtd_stop) {
    stopCam;
    return;
  }
  if(!is_void(freq)) rtd_freq = freq;

  yX=yY=sizex=sizey=0;
  _getROI, &yX, &yY, &sizex, &sizey;
  img=array(short(0), sizex, sizey);
  _acquire, &img, sizex, sizey, 1;
  rtd_img=int(img);
  ind = where(rtd_img<0);
  if(is_array(ind)) rtd_img(ind) += 65536;

  fma; pli, rtd_img; pause,100;

  xy = where2(rtd_img==max(rtd_img));
  plg, rtd_img(,xy(2));

  
  after, rtd_freq, rtd_loop;
}

func start_rtd( freq ){
  extern rtd_stop, rtd_img;

  if(startCam()) return;
  
  if(is_void(freq)) freq = 0.1;
  rtd_stop = 0;

  winkill, 10;
  window, 10, dpi=100;
  
  rtd_loop, freq;
}

func stop_rtd (void){
  extern rtd_stop;
  rtd_stop=1;
  stopCam;
}
