#include "ofMain.h"
#include "ofApp.h"

//========================================================================
int main( ){
  
    ofGLWindowSettings settings;
    settings.setGLVersion(3,2); /// < select your GL Version here
    ofCreateWindow(settings); ///< create your window here
    ofRunApp(new ofApp());


}
