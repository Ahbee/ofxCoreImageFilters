#pragma once

#include "ofMain.h"
#include "ofxCI.h"
#include "ofxGui.h"

class ofApp : public ofBaseApp{

	public:
		void setup();
		void update();
		void draw();

		void keyPressed(int key);
		void keyReleased(int key);
		void mouseMoved(int x, int y );
		void mouseDragged(int x, int y, int button);
		void mousePressed(int x, int y, int button);
		void mouseReleased(int x, int y, int button);
		void windowResized(int w, int h);
		void dragEvent(ofDragInfo dragInfo);
		void gotMessage(ofMessage msg);
    
    ofImage cupcake;
    ofImage whiteFlower;
    ofImage tiger;
    ofImage checkerBoard;
    ofImage smile;
    
    ofImage output1;
    ofImage output2;
    
    ofxCIFilter pageTurn;
    ofxCIFilter gloom;
    ofxCIFilter glassDistortion;
    ofxCIFilter sepia;
    ofxCIFilter vortex;
    ofxCIFilterChain chain;
    
    ofxPanel gui;
    
    ofxGuiGroup pageTurnSettings;
    ofxFloatSlider time;
    ofxFloatSlider angle;
    
    ofxGuiGroup gloomSettings;
    ofxFloatSlider gloomRadius;
    ofxFloatSlider gloomIntensity;
    
    ofxGuiGroup sepiaSettings;
    ofxFloatSlider sepiaIntensity;
    
    ofxGuiGroup glassDistortionSettings;
    ofxFloatSlider glassCenterX;
    ofxFloatSlider glassCenterY;
    ofxFloatSlider scale;
    
    ofxGuiGroup vortexSettings;
    ofxFloatSlider vortexCenterX;
    ofxFloatSlider vortexCenterY;
    ofxFloatSlider vortexRadius;
    ofxFloatSlider vortexAngle;
    
    ofxGuiGroup filterSettings;
    ofxToggle gloomOn;
    ofxToggle glassOn;
    ofxToggle sepiaOn;
    ofxToggle vortexOn;
};
