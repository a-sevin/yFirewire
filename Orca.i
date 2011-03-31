require, "libFW.i"
require,"util_fr.i";

func acquireOrca(origroix, origroiy, sizeroix, sizeroiy, nbframes, sumframes=)
/* DOCUMENT img = acquireOrca(origroix, origroiy, sizeroix, sizeroiy, nbframes, sumframes=)
      Permet d'acqurir un cube de nbframes images de la fenêtre souhaitée
      sumframes permet d'avoir la sommation de l'image et non le cube (défaut 0)
   SEE ALSO:
 */
{

  if ( !is_void(sizeroiy) ) 
    setROI, origroix, origroiy, sizeroix, sizeroiy;
  else {
    origroix=origroiy=sizeroix=sizeroiy=0;
    _getROI, &origroix, &origroiy, &sizeroix, &sizeroiy;
  }   
  
  if(startCam()) return;
  if ( is_void(sumframes) ) sumframes  = 0;
  if ( is_void(nbframes) ) nbframes  = 100;

  if(sumframes){
    img=array(long, sizeroix, sizeroiy);
    tmpimg=array(short, sizeroix, sizeroiy);
    tic;
    for(i=1; i<=nbframes; i++) {
      _acquire, &tmpimg, sizeroix, sizeroiy, 1;
      imgl=long(tmpimg);
      ind = where(imgl<0);
      if(is_array(ind)) imgl(ind) += 65536;
      img += imgl;
      if((i%50 == 0) || (i==nbframes)) {
        zTime = tac();
        etr = round((nbframes-i) / float(i) * zTime);
        fma;
        pli, img;
        colorbar, min(img), max(img); pause,0;
        pltitle,swrite(format=" iter : %d / %d (%0.2f%% : ETR %ds)", i, nbframes, i*100./nbframes, etr);
        pause,0;
      }
    }
    write, format = "freq = %f Hz\n", nbframes/tac();
  } else {
    img=array(short, sizeroix, sizeroiy, nbframes);
    tic;
    _acquire, &img, sizeroix, sizeroiy, nbframes;
    write, format = "freq = %f Hz\n", nbframes/tac();
    img=int(img);
    ind = where(img<0);
    if(is_array(ind)) img(ind) += 65536;
    if(nbframes == 1)
      img = img(,,1);
  }
  stopCam;
  return img;
}

rtd_stop = 1;
rtd_pup_val = 200;
rtd_pup = [];
rtd_pup_draw = [];
rtd_cuts = [];

func rtd_loop2( args )
/* DOCUMENT rtd_loop2, args
     Boucle du RTD
     A NE PAS LANCER SI ON NE SAIT PAS CE QUE L'ON FAIT
   SEE ALSO: start_rtd2, stop_rtd2
 */
{
  if(rtd_stop) {
    stopCam;
    return;
  }
  extern zmin, zmax, rtd_im, rtd_nb_img;
  
  freq = args(1);
  sizeroix = round(args(2));
  sizeroiy = round(args(3));
  nb_img = round(args(4));
  rtd_tmp=array(short(0), sizeroix, sizeroiy);
  _acquire, &rtd_tmp, sizeroix, sizeroiy, 1;
  rtd_img(,,rtd_nb_img)=rtd_tmp;
  if(is_void(zmax) || !is_void(rtd_cuts)) zmax = max(rtd_img(,,sum));
  if(is_void(zmin) || !is_void(rtd_cuts)) zmin = min(rtd_img(,,sum));
  if(!is_void(rtd_pup)) {
    tmp=rtd_tmp(, avg);
    xx = numberof(where(tmp>rtd_pup_val));
    if(rtd_pup_draw) {
      window,1; 
      fma;
      plg, tmp, marks=0;
      plg, [rtd_pup_val, rtd_pup_val], [0,numberof(tmp)], color="red", marks=0;
      pause, 0;
    }
    tmp=rtd_tmp(avg, );
    yy = numberof(where(tmp>rtd_pup_val));
    if(rtd_pup_draw) {
      window,2;
      fma;
      plg, tmp, marks=0;
      plg, [rtd_pup_val, rtd_pup_val], [0,numberof(tmp)], color="red", marks=0;
      pause, 0;
    }
  }
  window, 10;
  fma; pli, rtd_img(,,sum); //, cmin=zmin, cmax=zmax;
  if(!is_void(rtd_pup))
    pltitle,swrite(format="thres = %d : %d / %d", rtd_pup_val, xx, yy);
  colorbar, min(rtd_img(,,sum)), max(rtd_img(,,sum));
  pause,0;
  rtd_nb_img = rtd_nb_img%nb_img + 1;
  //write, format = "toto %f %d %d\n",freq, sizeroix, sizeroiy;
  after, freq, rtd_loop2, args;
}

func start_rtd2( freq, origroix, origroiy, sizeroix, sizeroiy, nb_img=, kill=)
/* DOCUMENT start_rtd2, freq, origroix, origroiy, sizeroix, sizeroiy, nb_img=, kill=
     Démarre un RTD
     freq : temps attente en s entre 2 boucles du RTD (defaut 0.1)
     nb_img : nombre d'images sommées affichées par le RTD (defaut 1, sommation glissante)
     kill : permet de créer une nouvelle fenêtre ou pas (defaut 1) 
   SEE ALSO:
 */
{
  extern rtd_stop, rtd_img, rtd_nb_img;

  if ( is_void(kill) ) kill  = 1;
  if ( is_void(freq) ) freq  = .1;
  rtd_stop = 0;
  
  if ( !is_void(sizeroiy) ) 
    setROI, origroix, origroiy, sizeroix, sizeroiy;
  else {
    origroix=origroiy=sizeroix=sizeroiy=0;
    _getROI, &origroix, &origroiy, &sizeroix, &sizeroiy;
  }   
  
  if(startCam()) return;
  if ( is_void(nb_img) ) nb_img  = 1;
  
  rtd_img=array(short(0), sizeroix, sizeroiy, nb_img);
  rtd_nb_img=1;
  
  if(kill) {
    winkill,10;
    window, 10, dpi=125;
  }
  fma; limits, square=1;
  palette, "gray.gp";
  rtd_loop2, [freq, sizeroix, sizeroiy, nb_img];
}


func stop_rtd2 (void)
/* DOCUMENT stop_rtd2
     Arret du RTD
     ATTENTION : la commande est ignorée quand on a le message :
     WARNING discarding keyboard input that aborts pause
   SEE ALSO:
 */
{
  extern rtd_stop;
  rtd_stop=1;
}
/*

** Démarrage de la caméra
expo = 400;
gain  = 100;
speed  = 800;
setupCam, expo, gain, speed=speed
setExpo, expo
setGain, gain

** Arrêt de la caméra
unsetupCam;

** Options pour afficher la taille de la pupille
rtd_pup_val = 200;  // seuil
rtd_pup = 1;        // taille dans le titre
rtd_pup_draw = 1;   // affichage des 2 graphs pour visualiser la coupe de la pupille

** Démarrer le RTD : freq, x, y, dx, dy
** (kill est par défault à 1 pour créer une nouvelle fenêtre)
start_rtd2, 0.1, 1, 1, 1344, 1024;
start_rtd2, 0.1, 1, 1, 1344, 1024, kill=0;
start_rtd2, 0.1, 650, 350, 150, 150;
start_rtd2, 0.1, 650, 350, 128, 128;

** Arrêt du RTD
** ATTENTION : la commande est ignorée quand on a le message :
** WARNING discarding keyboard input that aborts pause
stop_rtd2;

** Acquisition
** img = acquireOrca( x, y, dx, dy, nbframes);
** sumframes permet d'avoir la sommation de l'image et non le cube (défaut 0)
imgOL = acquireOrca( 610, 340, 128, 128, 256);
  
** Example d'acquisition longue pose
img = acquireOrca( 1, 1, 1344, 1024, 1000, sumframes=1);
fma; limits, square=1;
pli, img
colorbar, min(img), max(img)
max(img)
filename = swrite(format="meanimg500_pos105.5.fits")
fits_write, filename, img

img = acquireOrca( 1, 1, 1344, 1024, 50);
img = img(,,avg);
fma; limits, square=1
pli, img
colorbar, min(img), max(img)
max(img)
fits_write, "meanimg50_fond.fits", img

img = acquireOrca( 680, 360, 128, 128, 100);
img = img(,,avg);
pli, img
max(img)
//fits_write, "meanimg50_RefSrc.fits", img, overwrite=1
*/

func divphase(distance, nbimg, path, date, suff)
/* DOCUMENT img = divphase(distance, nbimg, path, date, suff)
     Permet d'acquérir et de sauver le résultat sous la forme :
     PATH/DATE_sumNBIMG_pos_DISTANCE_SUFF.fits

     Type des entrée :
     distance : long
     nbimg :    long
     path :     string
     date :     string
     suff :     string
   SEE ALSO:
 */
{
  img = acquireOrca( 1, 1, 1344, 1024, nbimg, sumframes=1);
  pli, img;
  colorbar, min(img), max(img)
  max(img);
  filename = swrite(format="%s/%s_sum%d_pos_%03.1f_%s.fits", path, date, nbimg,distance, suff);
  fits_write, filename, img;
  return img
}
