#include "ofxCIFIlter.h"

CIContext* ofxCIFilter::_context = nil;
CGColorSpaceRef ofxCIFilter::_colorSpace = nil;
NSOpenGLPixelFormat *_pf = nil;
NSOpenGLContext* ofxCIFilter::_glContext = nil;
unsigned int ofxCIFilter::clearCacheInterval = 8000;
bool ofxCIFilter::shouldAutoClear = true;
unsigned int ofxCIFilter::numberOfFilters = 0;

const BOOL OFX_USE_SOFTWARE_RENDERER = NO;


//-------------------------------------------------------------

void ofxCIFilter::disableAutoCacheClearing(){
    shouldAutoClear = false;
    ofEvents().update-= Poco::priorityDelegate(&ofxCIFilter::update, OF_EVENT_ORDER_APP);

}

void ofxCIFilter::enableAutoCacheClearing(){
    shouldAutoClear = true;
    ofEvents().update-= Poco::priorityDelegate(&ofxCIFilter::update, OF_EVENT_ORDER_APP);
    ofEvents().update+= Poco::priorityDelegate(&ofxCIFilter::update, OF_EVENT_ORDER_APP);
}

void ofxCIFilter::update(ofEventArgs &args){
    static int currentFrame = 0;
    if (currentFrame > clearCacheInterval) {
        clearCache();
        currentFrame = 0;
    }
    currentFrame++;
}

void ofxCIFilter::clearCache(){
    if (_context) {
        [_context release];
        CGLPixelFormatObj pfo = (CGLPixelFormatObj)[_pf CGLPixelFormatObj];
        CGLContextObj gclco = (CGLContextObj)[_glContext CGLContextObj];
        _context = [CIContext contextWithCGLContext:gclco pixelFormat:pfo colorSpace:_colorSpace
                    options:@{kCIContextUseSoftwareRenderer: [NSNumber numberWithBool:OFX_USE_SOFTWARE_RENDERER]}];
        [_context retain];
    }
}

void ofxCIFilter::setClearCacheInterval(unsigned int frames){
    clearCacheInterval = frames;
}

void ofxCIFilter::createContext(){
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        const NSOpenGLPixelFormatAttribute attr[] = {
            NSOpenGLPFAAccelerated,
            NSOpenGLPFANoRecovery,
            NSOpenGLPFAColorSize, 24,
            NSOpenGLPFAAlphaSize,8,
            NSOpenGLPFAOpenGLProfile,NSOpenGLProfileVersionLegacy,
            0
        };
        _colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
        _pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attr];
        _glContext = [[NSOpenGLContext alloc] initWithFormat:_pf shareContext:nil];
        CGLPixelFormatObj pfo = (CGLPixelFormatObj)[_pf CGLPixelFormatObj];
        CGLContextObj gclco = (CGLContextObj)[_glContext CGLContextObj];
        _context = [CIContext contextWithCGLContext:gclco pixelFormat:pfo colorSpace:_colorSpace
                    options:@{kCIContextUseSoftwareRenderer: [NSNumber numberWithBool:OFX_USE_SOFTWARE_RENDERER]}];
        if (_glContext == nil) {
            ofLogError("ofxCI") << "could not create context for Core Image";
            exit(1);
        }
        [_context retain];
        NSOpenGLContext* previousContext = [NSOpenGLContext currentContext];
        [_glContext makeCurrentContext];
        glClearColor(0, 0, 0, 1.0);
        [previousContext makeCurrentContext];
    });
}

//-------------------------------------------------------------

void ofxCIFilter::convertToARGB(ofImage &image){
    unsigned char *data = image.getPixels();
    int size = image.getWidth() * image.getHeight() * 4;
    for (int i = 0; i < size; i+=4) {
        unsigned char r = data[i];
        unsigned char g = data[i+1];
        unsigned char b = data[i+2];
        unsigned char a = data[i+3];
        data[i] = a;
        data[i+1] = r;
        data[i+2] = g;
        data[i+3] = b;
    }
}

//-------------------------------------------------------------

CIImage* ofxCIFilter::imageFrom(const ofImage &img){
    ofImage srcImage = img;
    srcImage.setImageType(OF_IMAGE_COLOR_ALPHA);
    convertToARGB(srcImage);
    srcImage.mirror(true, false);
    NSUInteger length = srcImage.getPixelsRef().size();
    NSUInteger bbp = 4;
    NSUInteger bpr = srcImage.getWidth() * 4;
    CGSize size = CGSizeMake(srcImage.getWidth(), srcImage.getHeight());
    NSData *bitmapData = [NSData dataWithBytes:srcImage.getPixels() length:length];
    CIImage *dst = [CIImage imageWithBitmapData:bitmapData bytesPerRow:bpr size:size format:kCIFormatARGB8 colorSpace:_colorSpace];
    return dst;
}

NSNumber* ofxCIFilter::numberFrom(float n){
    return [NSNumber numberWithFloat:n];
}

CIVector* ofxCIFilter::vectorFrom(const ofVec2f &v){
    CGPoint point = CGPointMake(v.x, v.y);
    return [CIVector vectorWithCGPoint:point];
}

CIVector* ofxCIFilter::vectorFrom(const ofRectangle &rect){
    return [CIVector vectorWithCGRect:CGRectMake(rect.getX(), rect.getY(), rect.getWidth(), rect.getHeight())];
}

NSAffineTransform* ofxCIFilter::transformFrom(const ofMatrix4x4 &mat){
    NSAffineTransformStruct transform;
    transform.m11 = mat._mat[0][0];
    transform.m12 = mat._mat[1][0];
    transform.m21 = mat._mat[0][1];
    transform.m22 = mat._mat[1][1];
    transform.tX = mat.getTranslation().x;
    transform.tY = mat.getTranslation().y;
    
    NSAffineTransform *t = [NSAffineTransform transform];
    [t setTransformStruct:transform];
    return t;
}

CIColor* ofxCIFilter::colorFrom(const ofFloatColor &color){
    return [CIColor colorWithRed:color.r green:color.g blue:color.b alpha:color.a];
}

//--------------------------------------------------------------

ofxCIFilter::ofxCIFilter(){
    _filter = nil;
    numberOfFilters++;
    if (numberOfFilters == 1 && shouldAutoClear == true) {
        ofEvents().update-= Poco::priorityDelegate(&ofxCIFilter::update, OF_EVENT_ORDER_APP);
        ofEvents().update+= Poco::priorityDelegate(&ofxCIFilter::update, OF_EVENT_ORDER_APP);
    }
}

ofxCIFilter::~ofxCIFilter(){
    [_filter release];
    numberOfFilters--;
    if (numberOfFilters == 0 && shouldAutoClear == true) {
        ofEvents().update-= Poco::priorityDelegate(&ofxCIFilter::update, OF_EVENT_ORDER_APP);
    }
}

//-------------------------------------------------------------

void ofxCIFilter::setup(OFX_FILTER_TYPE filter){
    createContext();
    NSString *string = [NSString stringWithUTF8String:filter.c_str()];
    _filter = [CIFilter filterWithName:string];
    [_filter retain];
    [_filter setDefaults];
    filterType = filter;
    inputWidth = 2;
    inputHeight = 2;
    
}

//-------------------------------------------------------------

void ofxCIFilter::getOutput(ofImage &outImage) const{
    getOutput(outImage,ofRectangle(0, 0, inputWidth, inputHeight));
}
//-------------------------------------------------------------

void ofxCIFilter::getOutput(ofImage &outImage, const ofRectangle &bounds)const{
    
    GLuint width = bounds.width;
    GLuint height = bounds.height;
    CGRect inRect = CGRectMake(0, 0, width, height);
    CGRect fromRect = CGRectMake(bounds.x,bounds.y,bounds.width,bounds.height);
    
    NSOpenGLContext* previousContext = [NSOpenGLContext currentContext];
    [_glContext makeCurrentContext];
    glViewport(0, 0, width, height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluOrtho2D(0.0, width ,0.0,height);
    
    GLuint framebuffer, renderbuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glGenRenderbuffers(1, &renderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, width,height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,GL_RENDERBUFFER, renderbuffer);
    glClear(GL_COLOR_BUFFER_BIT);
    
    CIImage *filterOut = [_filter valueForKey:kCIOutputImageKey];
    [_context drawImage:filterOut inRect:inRect fromRect:fromRect];
    
    GLubyte *data = (GLubyte*)malloc(width * height * 4);
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
    
    glDeleteRenderbuffers(1, &renderbuffer);
    glDeleteFramebuffers(1,&framebuffer);
    
    [previousContext makeCurrentContext];
    outImage.setFromPixels(data, width, height, OF_IMAGE_COLOR_ALPHA);
    free(data);
}

//-------------------------------------------------------------

void ofxCIFilter::printParameterError(string p ){
    ofLogError() << "'" << p << "' is not available for " << filterType << " call getAvailableSettings() for the list of available settings";
}

string ofxCIFilter::getType(NSString *attr){
    if ([attr compare:kCIAttributeTypeBoolean] == 0) {
        return "bool";
    }else if ([attr compare:kCIAttributeTypeInteger] == 0){
        return "int";
    }else if ([attr compare:kCIAttributeTypeCount]==0){
        return "unsigned int";
    }else if ([attr compare:kCIAttributeTypePosition] == 0){
        return "ofVec2f";
    }else if([attr compare:kCIAttributeTypeOffset]==0){
        return "ofVec2f";
    }else if ([attr compare:kCIAttributeTypePosition3]==0){
        return "ofVec3f";
    }else if ([attr compare:kCIAttributeTypeRectangle]==0){
        return "ofRectangle";
    }else if ([attr compare:kCIAttributeTypeOpaqueColor]==0){
        return "ofFloatColor";
    }else if ([attr compare:kCIAttributeTypeTime]==0){
        return "float";
    }else if([attr compare:kCIAttributeTypeDistance]==0){
        return "float";
    }else if([attr compare: kCIAttributeTypeGradient]==0){
        return "vector<float>";
    }else if([attr compare: kCIAttributeTypeScalar]==0){
        return "float";
    }else if([attr compare:kCIAttributeTypeAngle] == 0){
        return "float";
    }else{
        return "";
    }
}

string ofxCIFilter::getObjType(NSString *attr){
    if ([attr compare:@"CIImage"] == 0) {
        return "ofImage";
    }else if ([attr compare:@"NSAffineTransform"]==0){
        return "ofMatrix4x4";
    }else if ([attr compare:@"NSData"] == 0){
        return "Byte*";
    }else{
        return "";
    }
}

void ofxCIFilter::getAvailableSettings()const{
    NSArray *inputKeys = [_filter inputKeys];
    NSDictionary *attr = [_filter attributes];
    cout << filterType << ":\n\t";
    for (NSString* setting in inputKeys) {
        NSDictionary *settingAttr = [attr valueForKey:setting];
        NSString *sliderMin = nil;
        NSString *sliderMax = nil;
        NSString *typeAttr = nil;
        NSString *classObj = nil;
        @try {
            classObj = [settingAttr valueForKey:kCIAttributeClass];
            if (getObjType(classObj) != "") {
                cout << setw(20) << left << string([setting UTF8String]) << "type:" + getObjType(classObj);
            }
        }
        @catch (NSException *exception) {
            classObj = nil;
        }
        @try {
            typeAttr = [settingAttr valueForKey:kCIAttributeType];
        }
        @catch (NSException *exception) {
            typeAttr = nil;
        }
        if (getObjType(classObj) == "") {
            if (typeAttr) {
                cout << setw(20) << left << string([setting UTF8String]) << setw(17) << left << "type:" + getType(typeAttr);
            }else{
                cout << setw(20) << left << string([setting UTF8String]);
            }
        }
        @try {
            sliderMax = [settingAttr valueForKey:kCIAttributeSliderMax];
            sliderMin = [settingAttr valueForKey:kCIAttributeSliderMin];
        }
        @catch (NSException *exception) {
            sliderMax = nil;
            sliderMin = nil;
        }
        if (sliderMin && sliderMax) {
            float  max = [sliderMax floatValue];
            float  min = [sliderMin floatValue];
            cout <<  "range: " +  ofToString(min, 2) + " to " + ofToString(max, 2);
        }
        cout << "\n\t";
    }
    cout << endl;
}

void ofxCIFilter::setInputImage(const ofImage &image){
    CIImage* _image = imageFrom(image);
    @try {
        [_filter setValue:_image forKey:kCIInputImageKey];
    }
    @catch (NSException *exception) {
        printParameterError("Image");
    }
    inputWidth = image.width;
    inputHeight = image.height;
}

void ofxCIFilter::setInputBackgroundImage(const ofImage &backgroundImage){
    CIImage* _backgroundImage = imageFrom(backgroundImage);
    @try {
        [_filter setValue:_backgroundImage forKey:kCIInputBackgroundImageKey];
    }
    @catch (NSException *exception) {
        printParameterError("BackGroundImage");
    }
    
}

void ofxCIFilter::setInputTime(float time){
    NSNumber* _time = numberFrom(time);
    @try {
        [_filter setValue:_time forKey:kCIInputTimeKey];
    }
    @catch (NSException *exception) {
        printParameterError("Time");
    }
    
}

void ofxCIFilter::setInputTransform(const ofMatrix4x4 &affineTransform){
    NSAffineTransform* _affineTransform = transformFrom(affineTransform);
    @try{
        [_filter setValue:_affineTransform forKey:kCIInputTransformKey];
    }
    @catch(NSException *exception){
        printParameterError("Transform");
    }
}

void ofxCIFilter::setInputScale(float scale){
    NSNumber* _scale = numberFrom(scale);
    @try {
        [_filter setValue:_scale forKey:kCIInputScaleKey];
        
    }
    @catch (NSException *exception) {
        printParameterError("Scale");
    }
}

void ofxCIFilter::setInputAspectRatio(float aspectRatio){
    NSNumber* _aspectRatio = numberFrom(aspectRatio);
    @try {
        [_filter setValue:_aspectRatio forKey:kCIInputAspectRatioKey];
    }
    @catch (NSException *exception) {
        printParameterError("AspectRatio");
    }
    
}

void ofxCIFilter::setInputCenter(const ofVec2f &center){
    CIVector* _center = vectorFrom(center);
    @try {
        [_filter setValue:_center forKey:kCIInputCenterKey];
    }
    @catch (NSException *exception) {
        printParameterError("Center");
    }
    
}

void ofxCIFilter::setInputRadius(float radius){
    NSNumber *_radius = numberFrom(radius);
    @try {
        [_filter setValue:_radius forKey:kCIInputRadiusKey];
    }
    @catch (NSException *exception) {
        printParameterError("Radius");
    }
}

void ofxCIFilter::setInputAngle(float angle){
    NSNumber* _angle = numberFrom(angle);
    @try {
        [_filter setValue:_angle forKey:kCIInputAngleKey];
    }
    @catch (NSException *exception) {
        printParameterError("Angle");
    }
}

void ofxCIFilter::setInputRefraction(float refraction){
    NSNumber *_refraction = numberFrom(refraction);
    @try {
        [_filter setValue:_refraction forKey:kCIInputRefractionKey];
    }
    @catch (NSException *exception) {
        printParameterError("Refraction");
    }
}

void ofxCIFilter::setInputWidth(float width){
    NSNumber *_width = numberFrom(width);
    @try {
        [_filter setValue:_width forKey:kCIInputWidthKey];
    }
    @catch (NSException *exception) {
        printParameterError("Width");
    }
    
}

void ofxCIFilter::setInputSharpness(float sharpness){
    NSNumber *_sharpness = numberFrom(sharpness);
    @try {
        [_filter setValue:_sharpness forKey:kCIInputSharpnessKey];
    }
    @catch (NSException *exception) {
        printParameterError("Sharpeness");
    }
}

void ofxCIFilter::setInputIntensity(float intensity){
    NSNumber *_intensity = numberFrom(intensity);
    @try {
        [_filter setValue:_intensity forKey:kCIInputIntensityKey];
    }
    @catch (NSException *exception) {
        printParameterError("Intensity");
    }
}

void ofxCIFilter::setInputEV(float ev){
    NSNumber *_ev = numberFrom(ev);
    @try {
        [_filter setValue:_ev forKey:kCIInputEVKey];
    }
    @catch (NSException *exception) {
        printParameterError("EV");
    }
}

void ofxCIFilter::setInputSaturation(float saturation){
    NSNumber *_saturation = numberFrom(saturation);
    @try {
        [_filter setValue:_saturation forKey:kCIInputSaturationKey];
    }
    @catch (NSException *exception) {
        printParameterError("Saturation");
    }
}

void ofxCIFilter::setInputColor(ofFloatColor color){
    CIColor *_color = colorFrom(color);
    @try {
        [_filter setValue:_color forKey:kCIInputColorKey];
    }
    @catch (NSException *exception) {
        printParameterError("Color");
    }
}

void ofxCIFilter::setInputBrightness(float brightness){
    NSNumber *_brightness = numberFrom(brightness);
    @try {
        [_filter setValue:_brightness forKey:kCIInputBrightnessKey];
    }
    @catch (NSException *exception) {
        printParameterError("Brightness");
    }
}

void ofxCIFilter::setInputContrast(float contrast){
    NSNumber *_contrast = numberFrom(contrast);
    @try {
        [_filter setValue:_contrast forKey:kCIInputContrastKey];
    }
    @catch (NSException *exception) {
        printParameterError("Contrast");
    }
}

void ofxCIFilter::setInputGradientImage(const ofImage &gradientImage){
    CIImage *_gradientImage = imageFrom(gradientImage);
    @try {
        [_filter setValue:_gradientImage forKey:kCIInputGradientImageKey];
    }
    @catch (NSException *exception) {
        printParameterError("GradientImage");
    }
}

void ofxCIFilter::setInputMaskImage(const ofImage &maskImage){
    CIImage *_maskImage = imageFrom(maskImage);
    @try {
        [_filter setValue:_maskImage forKey:kCIInputMaskImageKey];
    }
    @catch (NSException *exception) {
        printParameterError("MaskImage");
    }
}

void ofxCIFilter::setInputShadingImage(const ofImage &shadingImage){
    CIImage *_shadingImage = imageFrom(shadingImage);
    @try {
        [_filter setValue:_shadingImage forKey:kCIInputShadingImageKey];
    }
    @catch (NSException *exception) {
        printParameterError("ShadingImage");
    }
}

void ofxCIFilter::setInputTargetImage(const ofImage &targetImage){
    CIImage *_targetImage = imageFrom(targetImage);
    @try {
        [_filter setValue:_targetImage forKey:kCIInputTargetImageKey];
    }
    @catch (NSException *exception) {
        printParameterError("TargetImage");
    }
    
}

void ofxCIFilter::setInputExtent(const ofRectangle &extent){
    CIVector *_extent = vectorFrom(extent);
    @try {
        [_filter setValue:_extent forKey:kCIInputExtentKey];
    }
    @catch (NSException *exception) {
        printParameterError("Extent");
    }
}

void ofxCIFilter::set(string parameterName, float scalar){
    NSString *key = [NSString stringWithUTF8String:parameterName.c_str()];
    NSNumber *value = [NSNumber numberWithFloat:scalar];
    @try {
        [_filter setValue:value forKey:key];
    }
    @catch (NSException *exception) {
        printParameterError(parameterName);
    }
}

void ofxCIFilter::set(string parameterName, int scalar){
    NSString *key = [NSString stringWithUTF8String:parameterName.c_str()];
    NSNumber *value = [NSNumber numberWithInteger:scalar];
    @try {
        [_filter setValue:value forKey:key];
    }
    @catch (NSException *exception) {
        printParameterError(parameterName);
    }
}

void ofxCIFilter::set(string parameterName, bool scalar){
    NSString *key = [NSString stringWithUTF8String:parameterName.c_str()];
    NSNumber *value = [NSNumber numberWithBool:scalar];
    @try {
        [_filter setValue:value forKey:key];
    }
    @catch (NSException *exception) {
        printParameterError(parameterName);
    }
}

void ofxCIFilter::set(string parameterName, const ofVec4f &v){
    
    NSString *key = [NSString stringWithUTF8String:parameterName.c_str()];
    CIVector *value = [CIVector vectorWithX:v.x Y:v.y Z:v.z W:v.w];
    @try {
        [_filter setValue:value forKey:key];
    }
    @catch (NSException *exception) {
        printParameterError(parameterName);
    }
    
}

void ofxCIFilter::set(string parameterName, const ofVec2f &v){
    
    NSString *key = [NSString stringWithUTF8String:parameterName.c_str()];
    CIVector *value = [CIVector vectorWithX:v.x Y:v.y];
    @try {
        [_filter setValue:value forKey:key];
    }
    @catch (NSException *exception) {
        printParameterError(parameterName);
    }
    
}

void ofxCIFilter::set(string parameterName, const ofVec3f &v){
    
    NSString *key = [NSString stringWithUTF8String:parameterName.c_str()];
    CIVector *value = [CIVector vectorWithX:v.x Y:v.y Z:v.z];
    @try {
        [_filter setValue:value forKey:key];
    }
    @catch (NSException *exception) {
        printParameterError(parameterName);
    }
    
}

void ofxCIFilter::set(string parameterName, const vector<float> &v){
    NSString *key = [NSString stringWithUTF8String:parameterName.c_str()];
    CIVector *value = [CIVector vectorWithValues:(const CGFloat*)v.data() count:v.size()];
    @try {
        [_filter setValue:value forKey:key];
    }
    @catch (NSException *exception) {
        printParameterError(parameterName);
    }
}

void ofxCIFilter::set(string parameterName, const ofImage &img){
    NSString *key = [NSString stringWithUTF8String:parameterName.c_str()];
    CIImage *value = imageFrom(img);
    @try {
        [_filter setValue:value forKey:key];
    }
    @catch (NSException *exception) {
        printParameterError(parameterName);
    }
}

void ofxCIFilter::set(string parameterName, const ofFloatColor &color){
    NSString *key = [NSString stringWithUTF8String:parameterName.c_str()];
    CIColor *value = colorFrom(color);
    @try {
        [_filter setValue:value forKey:key];
    }
    @catch (NSException *exception) {
        printParameterError(parameterName);
    }
}

void ofxCIFilter::set(string parameterName, const ofRectangle &rect){
    NSString *key = [NSString stringWithUTF8String:parameterName.c_str()];
    CIVector *value = vectorFrom(rect);
    @try {
        [_filter setValue:value forKey:key];
    }
    @catch (NSException *exception) {
        printParameterError(parameterName);
    }
}

void ofxCIFilter::set(string parameterName, const ofMatrix4x4 &affineTransform){
    NSString *key = [NSString stringWithUTF8String:parameterName.c_str()];
    NSAffineTransform *value = transformFrom(affineTransform);
    @try {
        [_filter setValue:value forKey:key];
    }
    @catch (NSException *exception) {
        printParameterError(parameterName);
    }
    
}

void ofxCIFilter::set(string parameterName, const Byte *data, size_t length){
    NSString *key = [NSString stringWithUTF8String:parameterName.c_str()];
    NSData *value = [NSData dataWithBytes:data length:length];
    @try {
        [_filter setValue:value forKey:key];
    }
    @catch (NSException *exception) {
        printParameterError(parameterName);
    }
}

void ofxCIFilter::set(string parameterName, NSObject *value){
    NSString *key = [NSString stringWithUTF8String:parameterName.c_str()];
    @try {
        [_filter setValue:value forKey:key];
    }
    @catch (NSException *exception) {
        printParameterError(parameterName);
    }
}

CIFilter* ofxCIFilter::getFilter()const{
    return _filter;
}

CIImage* ofxCIFilter::getOutput()const{
    return [_filter valueForKey:kCIOutputImageKey];
}

CIImage* ofxCIFilter::getInput()const{
    return [_filter valueForKey:kCIInputImageKey];
}

void ofxCIFilter::setInput(CIImage * image){
    [_filter setValue:image forKey:kCIInputImageKey];
}



