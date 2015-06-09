/*

 Digital, dynamic kaleidoscope.
 
 I N S T A L L A T I O N
 
#+ Connect the computer to the internet
#+ Connect the camera to the computer
#+ Make sure we have enough free space!
#+ Install the OpenCV library from the .DMG file
#+ Install the OpenCV Processing library in /Applications/Processing/Contents/Resources/Java/modes/libraries
#+ Move the sketch onto the Desktop
#+ Reconfigure the secure copy application
#+ Change the directory to be the sketch folder on the Desktop
#+ Change capture_source to the correct integer for an external iSight
 
 IDEA: show the live webcam feed until a face is detected, then change to kaleidoscope?
 
 Stuff that I learned:
  - Processing doesn't need to, can can't, do everything. Face tracking, video recording, and dynamic offscreen buffers were too taxing.
  - Incorporating audio is hard if you're not using an internal microphone on a Mac. This wasn't available to me.
  
 */

import processing.video.*; // native video libraries
// import hypermedia.video.*; // OpenCV library
// import java.awt.Rectangle; // for OpenCV

 Capture video; // video input variable

// set the source
// String video_source = "IIDC FireWire Video" ; // external iSight camera
 String video_source = "USB Video Class Video" ; // internal iSight camera

int capture_source = 0 ; // which camera? supercedes the video_source above!


// set the frame rate of the video to capture
int video_fps = 30 ; 

// set the width & height of the sketch
int video_width = 640 ;
int video_height = 480 ;

int sketch_width = 1920; // video_width; // 1920
int sketch_height = 1080; // video_height; // 1080


// other variables
PImage maskImage ; // mask image
PImage transparent_image ; 
PImage transparent_image_mirror ; 

int y_offset = -3 ; // this is to ensure the triangles overlap each other

PGraphics offscreen ;

// polygon info
int polygon_side_count = 6 ;
float triangle_offset ;
float angle_for_computation ;
float theta ; // this is the angle for BAD; see Polygon.pdf

boolean record_movie = false ;
MovieMaker kaleidoscope_recording;   // screen
MovieMaker webcam_recording;         // live camera feed
MovieMaker dynamic_mask;         // mask

/////OpenCV video; // for computer vision

void setup() {

  // fill background with black.
  background(0);

  size(sketch_width, sketch_height);
  frame.setBackground(new java.awt.Color(0, 0, 0));

  offscreen = createGraphics ( video_width, video_height, P2D );  

  // video = new Capture ( this, video_width, video_height, video_fps ) ;  // get the first available camera

  video = new Capture ( this, video_width, video_height, video_source, video_fps ) ; // get a specific camera
  /////video = new OpenCV(this);
  /////video.capture( video_width, video_height, capture_source );
  /////video.cascade( OpenCV.CASCADE_FRONTALFACE_ALT );    // load the FRONTALFACE description file

  // println ( Capture.list( ) ) ;  // output list of capture devices

  maskImage = loadImage("video-mask.png");

  // video.settings();
  offscreen = createGraphics ( video_width, video_height, P2D );  

  transparent_image = createImage(video_width, video_height, ARGB); // ARGB gives us transparency!!!!!
  transparent_image_mirror = createImage(video_width, video_height, ARGB); // ARGB gives us transparency!!!!!

angle_for_computation = 360.0 / polygon_side_count ;
}

void draw() {

  this.smooth();
  offscreen.smooth();

  video.read( ) ;

  /*
  else
   {
   println ( source + " camera is not connected to the computer." ) ;
   
   }
   */

  offscreen.beginDraw();
  offscreen.image ( video, 0, 0, video_width, video_height ) ; // output the video to the offscreen buffer
  // offscreen.fill(0);
  // offscreen.ellipse (640/2, (480/2)+250, 100, 100);
  offscreen.endDraw();

  offscreen.loadPixels() ;


  if ( record_movie )
  {
    // FIXME: adjust for bigger output
    kaleidoscope_recording.addFrame();
    webcam_recording.addFrame(offscreen.pixels, 640, 480);
    // dynamic_mask.addFrame(maskscreen.pixels, 640, 480);
  }

    transparent_image.loadPixels() ;

    // we want to load the pixels for the maskImage
    maskImage.loadPixels() ;

    // loop through it

    // get pixels from the video feed that are white in the mask
    // in the future, we could just draw a shape dynamically to the alternate buffer

    // columns
    for ( int col = 0; col < video_width; col++ )
    {
      // rows
      for ( int row = 0; row < video_height; row++ )
      {
        int loc = col + (row * video_width) ;
        // for each WHITE pixel of the mask image, grab the corresponding pixel
        // in the offscreen buffer and write to the transparent_image 
        // otherwise, leave the pixel "blank" (transparent?)

        if ( maskImage.pixels[loc] == color ( 255, 255, 255 ) )
        {
          transparent_image.pixels[loc] = color(red ( offscreen.pixels [loc] ), green ( offscreen.pixels[loc] ), blue ( offscreen.pixels[loc] ) );
        transparent_image_mirror.pixels[(video_width - col - 1) + row*video_width] = transparent_image.pixels[loc] ;

        }
      }
    }


    transparent_image.updatePixels();
    transparent_image_mirror.updatePixels();

    background ( 0 ) ;
  for ( int polygon = 0 ; polygon < polygon_side_count ; polygon++ )
  //   for ( int polygon = 0 ; polygon < 3 ; polygon++ )
  {
    // flip the odd ones
    if ( polygon%2 == 0 || polygon == 0 )
    {
      show_triangle ( false, angle_for_computation*polygon) ;
    }
    else
    {
      show_triangle ( true, angle_for_computation*polygon ) ;
    }
  }


  
}

void show_triangle ( boolean flip_horizontally, float rotation )
{

  pushMatrix( ) ; // needed for rotation
  translate ( width/2, height/2 ) ; // re-center the registration point: http://processing.org/discourse/yabb2/YaBB.pl?num=1251909297
  rotate (radians(rotation)) ;

  if ( flip_horizontally )
  {
    translate ( -sketch_width/2, -sketch_height/2 ) ; // re-center the registration point
    scale (2);
    image ( transparent_image_mirror, 160, 26  ) ;
  }
  else
  {
    translate ( -sketch_width/2, -sketch_height/2 ) ; // re-center the registration point
    scale (2);
    image ( transparent_image, 160, 26  ) ;
  }
  popMatrix( ) ; // needed for rotation
}

public void start_recording_movie ()
{

  
  // start recording
  record_movie = true ;
  //      int m = millis();

  String todays_date = nf(year(), 4) + nf(month(), 2) + nf(day(), 2) + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2) ;
  println ( "today's date/filename: " + todays_date ) ;
  kaleidoscope_recording = new MovieMaker(this, sketch_width, sketch_height, "kaleidoscope-" + todays_date + ".mov", 30, MovieMaker.H263, MovieMaker.HIGH);
  webcam_recording = new MovieMaker(this, video_width, video_height, "webcam-" + todays_date + ".mov", 30, MovieMaker.H263, MovieMaker.HIGH);
  // dynamic_mask = new MovieMaker(this, video_width, video_height, "mask-" + m + ".mov", 30, MovieMaker.H263, MovieMaker.HIGH);
}

public void stop_recording_movie ()
{
  // stop recording
  record_movie = false ;
  kaleidoscope_recording.finish();
  webcam_recording.finish();
  // dynamic_mask.finish();
  // copy the movie to the web
  //String[] params = { "/Users/saul/bin/secure-copy.sh" };
  // open ("/Users/saul/bin/secure-copy.sh") ;
  // open (params) ;
  // Runtime.getRuntime().exec("/Users/saul/bin/secure-copy.sh");

  //File workingDir = new File("/Users/saul/bin/");
  //String cmd = "secure-copy.sh" ;

  // Runtime.getRuntime().exec(cmd, null, workingDir);

  /*
#!/bin/bash
   
   # NOTE: an ssh key must be installed to make password-less login work!
   
   remote_user=sbaizman
   remote_host=baizman.net
   remote_directory=files
   scp=/usr/bin/scp
   dir="/Users/saul/kaleidoscope_dynamic_rev4"
   sleep 3
   
   $scp $dir/*.mov ${remote_user}@${remote_host}:${remote_directory}/
   
   touch $dir/copied
   
   */
}

void keyPressed ( )
{
  if ( key == ' ' )
  {
    if ( ! record_movie )
    {
      start_recording_movie();
    }
    else
    {
      stop_recording_movie();
    }
  }
}
/*
void mousePressed ()
{
  saveFrame ( "kaliedoscope-frame-######.png" ) ;
}
*/
