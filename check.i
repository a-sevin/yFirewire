include, "libFW.i";
include, "testcanary.i"; // pour la fonction cdg
 
func initFW(expo, gain){
  extern sizex, sizey;
  if ( is_void(expo)  ) expo  = 100;
  if ( is_void(gain)  ) gain  = 380;
  dimSize=setupCam(expo,gain);
  sizex=dimSize(1);
  sizey=dimSize(2);
}


func snap(nbframes){
  extern sizex, sizey;
  img = acquire(sizex, sizey, nbframes);
  pli, img(, , avg);
  //fits_write, "toto.fits", img, overwrite=1;
  return img;
}


func compute(nbIter){
  nbSP=10;
  pas= 6;
  csX=indgen(nbSP)* pas - pas+1;
  csY=indgen(nbSP)* pas - pas+1;
  method=0;
  if ( is_void(nbIter) ) nbIter=100;

  dimSize=setupCam(100,380);
  //stopCam;

  if(0){
    x0=0;
    y0=0;
    sizex=dimSize(1);
    sizey=dimSize(2);
  } else {
    x0=0;
    y0=0;
    sizex=80;
    sizey=60;
    setROI( x0, y0, sizex, sizey);
  }
  
  startCam;
  tic(0);
  //img=array(0.0, sizex, sizey);
  for(i=0; i<nbIter; i++){
    img = acquire(sizex, sizey, 1)(, , 1);
    res = cdg(img, csX, csY, pas, method);
    pli, img; pause, 0;
  }
  time=tac(0);
  stopCam;
  unsetupCam;

  write, format="nbIter = %d\ttime = %f s\tfreq = %f Hz\n", nbIter, time, nbIter/time;
}

func exposureXcdX710( ms )
{
 if( ms < 1000 ) {
   param = sqrt( 1000*ms );
   param = long( param+0.5 );  // pour arrondir a l'entier le plus proche
   if( param<3 ) param=3;
   return param;
 }
 param = (ms/1000. - 1.)*10 + 1000.;
 param = long( param+0.5 );  // pour arrondir a l'entier le plus proche
 if( param>1150 ) param=1150;
 return param;
}

func testExpo(expomin, expomax, expostep, gain, nbframes){
  extern sizex, sizey, tabExpoIMG, tabExpoValues;
  if ( is_void(expomin)  ) expomin  = 1;
  if ( is_void(expomax)  ) expomax  = 1000;
  if ( is_void(expostep)  ) expostep  = 100;
  if ( is_void(gain)  ) gain  = 380;
  if ( is_void(nbframes)  ) nbframes  = 10;
  dimSize=setupCam(expo,gain);
  sizex=dimSize(1);
  sizey=dimSize(2);
  img=array(double(0), sizex, sizey, nbframes);
  dimsExpo = int((expomax-expomin)/expostep)+1;
  tabExpoIMG = array(double(0), sizex, sizey, dimsExpo);
  tabExpoValues = array(double(0), dimsExpo);
  indexExpo=1;
  for(expo=expomin; expo<=expomax; expo+=expostep){
    _setExtShut, expo;
    startCam;
    img=array(short(0), sizex, sizey, nbframes);
    _acquire, &img, sizex, sizey, nbframes;
    stopCam;
    img=int(img);
    ind = where(img<0);
    if(is_array(ind)) img(ind) += 65536;
    tabExpoIMG(,,indexExpo) = img(,,avg);
    tabExpoValues(indexExpo++) =  expo;
  }
  unsetupCam;
  myImg = tabExpoIMG(*,);
  window, 0; fma; limits;
  plg, myImg(avg,), tabExpoValues;
  window, 1; fma; limits;
  plg, myImg(rms,), tabExpoValues;
}
