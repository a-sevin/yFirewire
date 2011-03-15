#include <stdlib.h>
#include <dc1394/dc1394.h>
#include <dc1394/vendor/avt.h>

dc1394camera_t *camera = NULL;	
dc1394error_t err;
dc1394video_mode_t video_mode;

void release_iso_and_bw()
//In this function, first we get the bandwidth usage value and release the resource accordingly, and then do the same for the ISO channel.
{
  if(camera==NULL) {
    dc1394_log_error("Camera is not initialised");
    return;
  }

  uint32_t val;
  if ( dc1394_video_get_bandwidth_usage(camera, &val) == DC1394_SUCCESS && dc1394_iso_release_bandwidth(camera, val) == DC1394_SUCCESS )
    printf("Succesfully released %d bytes of Bandwidth.\n",val);
  if ( dc1394_video_get_iso_channel(camera, &val) == DC1394_SUCCESS && dc1394_iso_release_channel(camera, val) == DC1394_SUCCESS )
    printf("Succesfully released ISO channel #%d.\n", val);
}

int _listFeatures(){
  if(camera==NULL) {
    dc1394_log_error("Camera is not initialised");
    return -1;
  }

    dc1394featureset_t features;

    /*-----------------------------------------------------------------------
     *  report camera's features
     *-----------------------------------------------------------------------*/
    err=dc1394_feature_get_all(camera,&features);
    if (err!=DC1394_SUCCESS) {
        dc1394_log_warning("Could not get feature set");
    }
    else {
        dc1394_feature_print_all(&features, stdout);
    }

    dc1394_avt_adv_feature_info_t adv_feature;
    dc1394_avt_get_advanced_feature_inquiry(camera, &adv_feature);
    if (err!=DC1394_SUCCESS) {
        dc1394_log_warning("Could not get adv feature set");
    }
    else {
      dc1394_avt_print_advanced_feature(&adv_feature);
    }

}

int _setupCam(long yExpo, long yGain, long *sizex, long *sizey, long speed){
  dc1394camera_list_t * list;
  dc1394_t *d = dc1394_new ();
  if (!d)
    return -1;

  dc1394speed_t iso_speed;
   if(speed == 400) 
     iso_speed = DC1394_ISO_SPEED_400; 
   else if(speed == 800) 
     iso_speed = DC1394_ISO_SPEED_800; 
   else 
     return -1; 
   //iso_speed = DC1394_ISO_SPEED_400;

  dc1394_log_register_handler(DC1394_LOG_WARNING, NULL, NULL);
  err=dc1394_camera_enumerate (d, &list);
  DC1394_ERR_RTN(err,"Failed to enumerate cameras");
	
  if (list->num == 0) {
    dc1394_log_error("No cameras found");
    return -1;
  }
	
  camera = dc1394_camera_new (d, list->ids[0].guid);
  if (!camera) {
    dc1394_log_error("Failed to initialize camera with guid %lld", list->ids[0].guid);
    return -1;
  }
  dc1394_camera_free_list (list);
	
  printf("Using camera with GUID %lld\n", camera->guid);
	
  release_iso_and_bw();

  uint32_t expo = yExpo; 
  uint32_t gain = yGain;

  /*-----------------------------------------------------------------------
   *  setup capture
   *-----------------------------------------------------------------------*/
  dc1394_video_set_operation_mode(camera, DC1394_OPERATION_MODE_1394B);
  DC1394_ERR_CLN_RTN(err,_unsetupCam(),"Could not set operation mode");

  err=dc1394_video_set_iso_speed(camera, iso_speed);
  DC1394_ERR_CLN_RTN(err,_unsetupCam(),"Could not set iso speed");

  _setVideoMode(0, sizex, sizey);

  err=dc1394_feature_set_value(camera, DC1394_FEATURE_GAIN, gain);
  DC1394_ERR_CLN_RTN(err,_unsetupCam(),"Could not define gain");

  err=dc1394_feature_set_value(camera, DC1394_FEATURE_SHUTTER, expo);
  DC1394_ERR_CLN_RTN(err,_unsetupCam(),"Could not define shutter");

  return 0;
}

int _unsetupCam(){
  if(_stopCam()) return;
  dc1394_camera_free(camera);
  camera = NULL;
  return 0;
}

int _setVideoMode(int mode, long *sizex, long *sizey){
  if(camera==NULL) {
    dc1394_log_error("Camera is not initialised");
    return -1;
  }

  switch(mode) { 
  case 0 : video_mode=DC1394_VIDEO_MODE_FORMAT7_0;break;
  case 1 : video_mode=DC1394_VIDEO_MODE_FORMAT7_1;break;
  case 2 : video_mode=DC1394_VIDEO_MODE_FORMAT7_2;break;
  case 3 : video_mode=DC1394_VIDEO_MODE_FORMAT7_3;break;
  default : ;
  }
  unsigned int h_size = 160;
  unsigned int v_size = 120;

  err = dc1394_format7_get_max_image_size(camera, video_mode, &h_size, &v_size);
  DC1394_ERR_CLN_RTN(err,_unsetupCam(),"Could not get max image size of Format7 mode");
  *sizex = h_size;
  *sizey = v_size;

  err = dc1394_video_set_mode(camera, video_mode);
  DC1394_ERR_CLN_RTN(err,_unsetupCam(),"Could not set Format7 mode");

  err = dc1394_format7_set_roi(camera, video_mode,
			       DC1394_COLOR_CODING_MONO16,
			       DC1394_USE_MAX_AVAIL, // use max packet size
			       0, 0, // left, top
			       h_size, v_size);  // width, height
  DC1394_ERR_RTN(err,"Unable to set Format7 mode 0.\nEdit the example file manually to fit your camera capabilities");

  return 0;
}

int _startCam(){
  if(camera==NULL) {
    dc1394_log_error("Camera is not initialised");
    return -1;
  }

  err=dc1394_capture_setup(camera, 4, DC1394_CAPTURE_FLAGS_DEFAULT);
  // err=dc1394_capture_setup(camera, 4, DC1394_CAPTURE_FLAGS_AUTO_ISO);
  // err=dc1394_capture_setup(camera, 4, DC1394_CAPTURE_FLAGS_CHANNEL_ALLOC & DC1394_CAPTURE_FLAGS_BANDWIDTH_ALLOC);
  DC1394_ERR_CLN_RTN(err,_unsetupCam(),"Could not setup camera-\nmake sure that the video mode and framerate are\nsupported by your camera");

	
  /*-----------------------------------------------------------------------
   *  print allowed and used packet size
   *-----------------------------------------------------------------------*/
  unsigned int min_bytes, max_bytes;
  unsigned int actual_bytes;
  uint64_t total_bytes = 0;
  err=dc1394_format7_get_packet_parameters(camera, video_mode, &min_bytes, &max_bytes);
  
  DC1394_ERR_RTN(err,"Packet para inq error");
  //printf( "camera reports allowed packet size from %d - %d bytes\n", min_bytes, max_bytes);
  
  err=dc1394_format7_get_packet_size(camera, video_mode, &actual_bytes);
  DC1394_ERR_RTN(err,"dc1394_format7_get_packet_size error");
  //printf( "camera reports actual packet size = %d bytes\n", actual_bytes);
  
  err=dc1394_format7_get_total_bytes(camera, video_mode, &total_bytes);
  DC1394_ERR_RTN(err,"dc1394_query_format7_total_bytes error");
  //printf( "camera reports total bytes per frame = %lld bytes\n",total_bytes);

  /*-----------------------------------------------------------------------
   *  have the camera start sending us data
   *-----------------------------------------------------------------------*/
  err=dc1394_video_set_transmission(camera, DC1394_ON);
  DC1394_ERR_CLN_RTN(err,_unsetupCam(),"Could not start camera iso transmission");

  return 0;
}

int _getBinning(uint32_t *sX, uint32_t *sY){
  if(camera==NULL) {
    dc1394_log_error("Camera is not initialised");
    return -1;
  }

  err=dc1394_format7_get_unit_size(camera, video_mode, sX, sY);
  DC1394_ERR_RTN(err,"Unable to set Format7 mode 0.\nEdit the example file manually to fit your camera capabilities");
	
  return 0;
}

int _getMaxRes(uint32_t *sX, uint32_t *sY){
  if(camera==NULL) {
    dc1394_log_error("Camera is not initialised");
    return -1;
  }

  err=dc1394_avt_get_MaxResolution(camera, sX, sY);
  DC1394_ERR_RTN(err,"Unable to set Format7 mode 0.\nEdit the example file manually to fit your camera capabilities");
	
  return 0;
}

int _setHSNR(long yOnOff, long grabCount){
  if(camera==NULL) {
    dc1394_log_error("Camera is not initialised");
    return -1;
  }

  err=dc1394_avt_set_hsnr(camera, yOnOff, grabCount);
  DC1394_ERR_CLN_RTN(err,_unsetupCam(),"Could not define HSNR");
	
  return 0;
}

int _getHSNR(dc1394bool_t *yOnOff, uint32_t *grabCount){
  if(camera==NULL) {
    dc1394_log_error("Camera is not initialised");
    return -1;
  }

  err=dc1394_avt_get_hsnr(camera, yOnOff, grabCount);
  DC1394_ERR_CLN_RTN(err,_unsetupCam(),"Could not get HSNR");
	
  return 0;
}

int _setExpo(long yExpo){
  if(camera==NULL) {
    dc1394_log_error("Camera is not initialised");
    return -1;
  }

  err=dc1394_feature_set_value(camera, DC1394_FEATURE_SHUTTER, yExpo);
  DC1394_ERR_CLN_RTN(err,_unsetupCam(),"Could not define shutter");
	
  return 0;
}

int _getExpo(){
  if(camera==NULL) {
    dc1394_log_error("Camera is not initialised");
    return -1;
  }

  uint32_t expo = 0; 
  err=dc1394_feature_get_value(camera, DC1394_FEATURE_SHUTTER, &expo);
  DC1394_ERR_CLN_RTN(err,_unsetupCam(),"Could not get shutter");
	
  return expo;
}

int _setExtShut(long yExpo){
  if(camera==NULL) {
    dc1394_log_error("Camera is not initialised");
    return -1;
  }

  err=dc1394_avt_set_extented_shutter(camera, yExpo);
  DC1394_ERR_CLN_RTN(err,_unsetupCam(),"Could not define extented shutter");
	
  return 0;
}

int _getExtShut(){
  if(camera==NULL) {
    dc1394_log_error("Camera is not initialised");
    return -1;
  }

  uint32_t expo = 0; 
  err=dc1394_avt_get_extented_shutter(camera, &expo);
  DC1394_ERR_CLN_RTN(err,_unsetupCam(),"Could not get extented shutter");
	
  return expo;
}

int _setGain(long yGain){
  if(camera==NULL) {
    dc1394_log_error("Camera is not initialised");
    return -1;
  }

  err=dc1394_feature_set_value(camera, DC1394_FEATURE_GAIN, yGain);
  DC1394_ERR_CLN_RTN(err,_unsetupCam(),"Could not define gain");

  return 0;
}

int _getGain(){
  if(camera==NULL) {
    dc1394_log_error("Camera is not initialised");
    return -1;
  }

  uint32_t gain = 0;
  err=dc1394_feature_get_value(camera, DC1394_FEATURE_GAIN, &gain);
  DC1394_ERR_CLN_RTN(err,_unsetupCam(),"Could not get gain");

  return gain;
}

int _setROI(long yX, long yY, long ySizeX, long ySizeY){
  if(camera==NULL) {
    dc1394_log_error("Camera is not initialised");
    return -1;
  }

  err = dc1394_format7_set_roi(camera, video_mode,
			       DC1394_COLOR_CODING_MONO16,
			       DC1394_USE_MAX_AVAIL, // use max packet size
			       yX, yY, // left, top
			       ySizeX, ySizeY);  // width, height
  DC1394_ERR_CLN_RTN(err,_unsetupCam(),"Could not define ROI");

  return 0;
}

int _getROI(int *yX, int *yY, int *ySizeX, int *ySizeY){
  if(camera==NULL) {
    dc1394_log_error("Camera is not initialised");
    return -1;
  }

  dc1394color_coding_t color_coding;
  int bytes_per_packet;
  err = dc1394_format7_get_roi(camera, video_mode,
			       &color_coding,
			       &bytes_per_packet, 
			       yX, yY, // left, top
			       ySizeX, ySizeY);  // width, height
  DC1394_ERR_CLN_RTN(err,_unsetupCam(),"Could not get ROI");

  return 0;
}

int _stopCam(){
  if(camera==NULL) {
    dc1394_log_error("Camera is not initialised");
    return -1;
  }

  /*-----------------------------------------------------------------------
   *  stop data transmission
   *-----------------------------------------------------------------------*/
  err=dc1394_video_set_transmission(camera,DC1394_OFF);
  DC1394_ERR_CLN_RTN(err,_unsetupCam(),"Could not stop transmission of the camera");
  err=dc1394_capture_stop(camera);
  DC1394_ERR_CLN_RTN(err,_unsetupCam(),"Could not stop capture of the camera");
  return 0;
}

int _acquire(short *yFrames, long sizex, long sizey, long yNbFrames ){
  if(camera==NULL) {
    dc1394_log_error("Camera is not initialised");
    return -1;
  }


  dc1394video_frame_t *frame;

  int nbframes  = yNbFrames;

  long j=0;
  while( j<nbframes) {
    /*-----------------------------------------------------------------------
     *  capture one frame
     *-----------------------------------------------------------------------*/
    //fprintf(stderr,"Trying... \n");
    
    err=dc1394_capture_dequeue(camera, DC1394_CAPTURE_POLICY_WAIT, &frame);
    DC1394_ERR_CLN_RTN(err,_unsetupCam(),"Could not capture a frame");
    
    
    if( 1 ) {
      unsigned int i=0;
      for(i=0; i<sizex*sizey; i++)
	yFrames[j*sizex*sizey+i] = frame->image[2*i]*256 + frame->image[2*i+1];
    } else {
      //impossible de passer par memcpy car Yorick ne gere pas les unsigned.
      //memcpy((void *)&yFrames[j*sizex*sizey], (void *)frame->image, sizex*sizey*sizeof(short));
    }


    // release buffer    
    err=dc1394_capture_enqueue(camera,frame);
    DC1394_ERR_CLN_RTN(err,_unsetupCam(),"Could not return frame");
    
    j++;
  }
  return 0;
}
