#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
    cam.initGrabber(640, 480,false);
    ofDisableArbTex();
    ofSetupScreenPerspective();
    ofSetFrameRate(30.0);
    
    box.set(200, 200, 200);
    box.setPosition(810, 560, 0);
    
    gui.setup();
    gui.add(angle.setup("angle",0,-3.14,3.14));
    gui.add(width.setup("width",150,100,200));
    gui.setPosition(800, 20);
    
    // setup filters
    parallelogram.setup(OFX_FILTER_TYPE_PARALLELOGRAM_TILE);
    parallelogram.getAvailableSettings();
    parallelogram.setInputCenter(ofVec2f(cam.getWidth()/2,cam.getHeight()/2));
}

//--------------------------------------------------------------
void ofApp::update(){
    box.rotate(1, ofVec3f(0,1,0));
    cam.update();
    if (cam.isFrameNew()) {
        inputOutput.setFromPixels(cam.getPixelsRef());
        parallelogram.setInputImage(inputOutput);
        parallelogram.setInputAngle(angle);
        parallelogram.setInputWidth(width);
        parallelogram.getOutput(inputOutput);
    }
}

//--------------------------------------------------------------
void ofApp::draw(){
    inputOutput.draw(0, 0);
    
    ofEnableDepthTest();
    inputOutput.bind();
    box.draw();
    inputOutput.unbind();
    
    ofDisableDepthTest();
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
