#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
    // load images
    cupcake.load("cupcake.jpg");
    whiteFlower.load("whiteFlower.jpg");
    tiger.load("tiger.jpg");
    checkerBoard.load("checker.jpg");
    smile.load("smile.png");
    checkerBoard.resize(tiger.getWidth(), tiger.getHeight());
    smile.resize(cupcake.getWidth(), cupcake.getHeight());
    
    // setup gui
    gui.setup();
    pageTurnSettings.setup("PageTurn Settings");
    sepiaSettings.setup("Sepia Settings");
    glassDistortionSettings.setup("GlassDistortion Settings");
    vortexSettings.setup("Vortex settings");
    filterSettings.setup("Chain settings");
    gloomSettings.setup("Gloom Settings");
    pageTurnSettings.add(time.setup("time",.4,0,1));
    pageTurnSettings.add(angle.setup("angle",-.67,-M_PI,M_PI));
    sepiaSettings.add(sepiaIntensity.setup("Intensity",.9,0,1));
    gloomSettings.add(gloomRadius.setup("Radius",40,0,100));
    gloomSettings.add(gloomIntensity.setup("Intensity",1,0,1));
    glassDistortionSettings.add(glassCenterX.setup("centerX",0,0,cupcake.getWidth()));
    glassDistortionSettings.add(glassCenterY.setup("centerY",0,0,cupcake.getHeight()));
    vortexSettings.add(vortexCenterX.setup("centerX",100,0,cupcake.getWidth()));
    vortexSettings.add(vortexCenterY.setup("centerY",100,0,cupcake.getHeight()));
    vortexSettings.add(vortexRadius.setup("radius",400,0,800));
    vortexSettings.add(vortexAngle.setup("angle",70,-90,90));
    glassDistortionSettings.add(scale.setup("scale",200,1,500));
    filterSettings.add(gloomOn.setup("gloom",true));
    filterSettings.add(sepiaOn.setup("sepia",true));
    filterSettings.add(glassOn.setup("glassDistortion",true));
    filterSettings.add(vortexOn.setup("vortex",true));
    
    gui.add(&pageTurnSettings);
    gui.add(&gloomSettings);
    gui.add(&sepiaSettings);
    gui.add(&glassDistortionSettings);
    gui.add(&vortexSettings);
    gui.add(&filterSettings);
    
    
    // setup filters
    pageTurn.setup(OFX_FILTER_TYPE_PAGE_CURL_WITH_SHADOW_TRANSITION);
    pageTurn.getAvailableSettings();
    pageTurn.setInputImage(tiger);
    pageTurn.setInputTargetImage(whiteFlower);
    pageTurn.setInputExtent(ofRectangle(0, 0, tiger.getWidth(), tiger.getHeight()));
    pageTurn.set("inputBacksideImage",checkerBoard);
    
    gloom.setup(OFX_FILTER_TYPE_GLOOM);
    gloom.getAvailableSettings();
    gloom.setInputImage(cupcake);
    
    sepia.setup(OFX_FILTER_TYPE_SEPIA_TONE);
    sepia.getAvailableSettings();
    
    glassDistortion.setup(OFX_FILTER_TYPE_GLASS_DISTORTION);
    glassDistortion.getAvailableSettings();
    glassDistortion.set("inputTexture",smile);
    
    vortex.setup(OFX_FILTER_TYPE_VORTEX_DISTORTION);
    vortex.getAvailableSettings();
    
    // add filters to a chain
    chain.addFilter(gloom);
    chain.addFilter(sepia);
    chain.addFilter(glassDistortion);
    chain.addFilter(vortex);


}

//--------------------------------------------------------------
void ofApp::update(){
    // update all the parameters from the gui
    pageTurn.setInputTime(time);
    pageTurn.setInputAngle(angle);
    
    gloom.setInputRadius(gloomRadius);
    gloom.setInputIntensity(gloomIntensity);
    sepia.setInputIntensity(sepiaIntensity);
    glassDistortion.setInputCenter(ofVec2f(glassCenterX,glassCenterY));
    glassDistortion.setInputScale(scale);
    vortex.setInputCenter(ofVec2f(vortexCenterX,vortexCenterY));
    vortex.setInputRadius(vortexRadius);
    vortex.setInputAngle(vortexAngle);
    
    chain.setState(0, gloomOn);
    chain.setState(1, sepiaOn);
    chain.setState(2, glassOn);
    chain.setState(3, vortexOn);
    
    // get the results of the filters
    pageTurn.getOutput(output1);
    chain.getOutput(output2);
}

//--------------------------------------------------------------
void ofApp::draw(){
    output1.draw(250, 20);
    output2.draw(250,375);
    ofDrawBitmapString("This effect is a 'Page Transition'\nuse the PageTurn Settings to modify", ofPoint(730,100));
    ofDrawBitmapString("This effect uses an ofxCIFilterChain\nto chain together 4 effects;gloom,\nsepia,glass distortion,and voretx.\nUse the Chain settings to toggle\neffects in the chain on and off", ofPoint(630,500));
    gui.draw();
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){
    
}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){

}

//--------------------------------------------------------------
void ofApp::mouseMoved(int x, int y ){

}

//--------------------------------------------------------------
void ofApp::mouseDragged(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mousePressed(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseReleased(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::windowResized(int w, int h){

}

//--------------------------------------------------------------
void ofApp::gotMessage(ofMessage msg){

}

//--------------------------------------------------------------
void ofApp::dragEvent(ofDragInfo dragInfo){ 

}
