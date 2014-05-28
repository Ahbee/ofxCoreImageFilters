#pragma once
#include "ofxCIFilter.h"

class ofxCIFilterChain {
public:
    void addFilter(ofxCIFilter &filter);
    void removeFilter(int index);
    void insertFilter(ofxCIFilter &filter,int index);
    void disable(int index);
    void enable(int index);
    void disableAll();
    void enableAll();
    void setState(int index,bool value);
    void getState(int index) const;
    void removeAllFilters();
    void getOutput(ofImage &outImage)const;
    void getOutput(ofImage &outImage,const ofRectangle &bounds)const;
    
private:
    struct filterNode{
        filterNode(ofxCIFilter* f){
            filter = f;
            state = true;
        }
         ofxCIFilter *filter;
        bool state;
    };
    vector<filterNode> nodes;

private:
    // these functions are only there to enforce users to use only ofImage for output
    template<typename T>
    void getOutput(T arg1) const;
    template<typename T>
    void getOutput(T arg1,const ofRectangle& bounds) const;
};