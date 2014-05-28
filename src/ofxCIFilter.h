#pragma once
#include "ofMain.h"
#include "ofxCIConstants.h"
#import <QuartzCore/QuartzCore.h>

class ofxCIFilter {
public:
    ofxCIFilter();
    ~ofxCIFilter();
    
    void setup(OFX_FILTER_TYPE filter);
    
    // gets the result of the filter
    // always returns a 4 channel image.
    void getOutput(ofImage &outImage) const;
        
    // use this function if you want to get a diffrent region of your OutImage;
    // useful for filters that modify the dimensions of an image
    // always returns a 4 channel image
    void getOutput(ofImage &outImage,const ofRectangle& bounds) const;
    
    // prints the list of parameters along with their type and range
    void getAvailableSettings() const;
    
    // most filters will use a subset of these parameters
    void setInputImage(const ofImage &image);
    void setInputBackgroundImage(const ofImage &backgroundImage);
    void setInputTime(float time);
    void setInputTransform(const ofMatrix4x4 &affineTransform);
    void setInputScale(float scale);
    void setInputAspectRatio(float aspectRatio);
    void setInputCenter(const ofVec2f &center);
    void setInputRadius(float radius);
    void setInputAngle(float angle);
    void setInputRefraction(float refraction);
    void setInputWidth(float width);
    void setInputSharpness(float sharpness);
    void setInputIntensity(float intensity);
    void setInputEV(float ev);
    void setInputSaturation(float saturation);
    void setInputColor(ofFloatColor color);
    void setInputBrightness(float brightness);
    void setInputContrast(float contrast);
    void setInputGradientImage(const ofImage& gradientImage);
    void setInputMaskImage(const ofImage& maskImage);
    void setInputShadingImage(const ofImage& shadingImage);
    void setInputTargetImage(const ofImage& targetImage);
    void setInputExtent(const ofRectangle &extent);
    
    // for the filters that use additional parameters use these functions
    void set(string parameterName,float f);
    void set(string parameterName,int i);
    void set(string parameterName,bool b);
    void set(string parameterName,const ofVec4f&v);
    void set(string parameterName,const ofVec3f&v);
    void set(string parameterName,const ofVec2f&v);
    void set(string parameterName,const vector<float> &v);
    void set(string parameterName,const ofImage &img);
    void set(string parameterName,const ofFloatColor &color);
    void set(string parameterName,const ofRectangle &rect);
    void set(string parameterName,const ofMatrix4x4 &affineTransform);
    void set(string parameterName,const Byte *data, size_t length);
    
    // use this if none of the other 'set' functions match your needs
    void set(string parameterName, NSObject *value);
    
    // frees memory used by the context. Users generally dont need to call this function.
    // It is called automatically every 8000 frames by default.
    static void clearCache();
    
    // sets the number of frames to wait in between calls to clearCache(). It is 8000 by default.
    // longer frames intervals give better memory managment.
    static void setClearCacheInterval(unsigned int frames);
    
    // disables auto cache clearing, the user must call clearCache() manually.
    static void disableAutoCacheClearing();
    
    // enables auto cache clearing
    static void enableAutoCacheClearing();
    
private:
    CIFilter *_filter;
    OFX_FILTER_TYPE filterType;
    int inputWidth;
    int inputHeight;
    void printParameterError(string p);
    CIFilter* getFilter()const;
    CIImage* getOutput()const;
    CIImage* getInput()const;
    void setInput(CIImage *img);
    friend class ofxCIFilterChain;
private:
    static CIContext* _context;
    static NSOpenGLContext *_glContext;
    static CGColorSpaceRef _colorSpace;
    static unsigned int clearCacheInterval;
    static bool shouldAutoClear;
    static unsigned int numberOfFilters;
    static void update(ofEventArgs &args);
    static void createContext();
    static CIImage* imageFrom(const ofImage &img);
    static NSNumber* numberFrom(float n);
    static CIVector* vectorFrom(const ofVec2f &v);
    static NSAffineTransform* transformFrom(const ofMatrix4x4 &mat);
    static CIVector* vectorFrom(const ofRectangle &rect);
    static CIColor* colorFrom(const ofFloatColor &color);
    static void convertToARGB(ofImage& image);
    static std::string getType(NSString* attr);
    static std::string getObjType(NSString *attr);
    static void convertFromCGImage(ofImage &dst,CGImageRef src);
private:
    // these functions are only there to enforce users to only use ofImage type for inputs and output
    template<typename T>
    void setInputImage(T arg1);
    template<typename T>
    void setInputBackgroundImage(T arg2);
    template<typename T>
    void setGradientImage(T arg2);
    template<typename T>
    void setInputMaskImage(T arg2);
    template<typename T>
    void setInputShadingImage(T arg2);
    template<typename T>
    void setInputTargetImage(T arg2);
    void set(string parameterName, ofFloatImage img);
    void set(string parameterName, ofShortImage img);
    template<typename T>
    void getOutput(T arg1)const;
    template<typename T>
    void getOutput(T arg1,const ofRectangle& bounds)const;
};


