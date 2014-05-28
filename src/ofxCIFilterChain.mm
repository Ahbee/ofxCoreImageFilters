#include "ofxCIFilterChain.h"


void ofxCIFilterChain::addFilter(ofxCIFilter &filter){
    filterNode n(&filter);
    nodes.push_back(n);
}

void ofxCIFilterChain::removeFilter(int index){
    try {
        nodes.erase(nodes.begin()+index);
    } catch (exception &e) {
        ofLog() << "cannot remove filter at index " << index;
    }
}

void ofxCIFilterChain::insertFilter(ofxCIFilter &filter,int index){
    filterNode f(&filter);
    try {
        nodes.insert(nodes.begin()+index, f);
    } catch (exception &e) {
        ofLog() << "cannot insert filter at index " << index;
    }
}

void ofxCIFilterChain::disable(int index){
    try {
        nodes[index].state = false;
    } catch (exception &e) {
        ofLog() << "cannot disable filter at index " << index;
    }
}

void ofxCIFilterChain::disableAll(){
    for (int i = 0; i < nodes.size(); i++) {
        nodes[i].state = false;
    }
}

void ofxCIFilterChain::enable(int index){
    try {
        nodes[index].state = true;
    } catch (exception &e) {
        ofLog() << "cannot disable filter at index " << index;
    }
}

void ofxCIFilterChain::enableAll(){
    for (int i = 0; i < nodes.size(); i++) {
        nodes[i].state = true;
    }
}

void ofxCIFilterChain::setState(int index, bool value){
    try {
        nodes[index].state = value;
    } catch (exception &e) {
        ofLog() << "cannot set state at index " << index;
    }
}

void ofxCIFilterChain::getState(int index) const{
    bool state;
    try {
        state = nodes[index].state;
    } catch (exception &e) {
        ofLog() << "cannot get state at index " << index;
    }
    return state;
}

void ofxCIFilterChain::removeAllFilters(){
    nodes.clear();
}

void ofxCIFilterChain::getOutput(ofImage &outImage)const{
    int width = nodes[0].filter->inputWidth;
    int height = nodes[0].filter->inputHeight;
    getOutput(outImage,ofRectangle(0, 0,width , height));
}

void ofxCIFilterChain::getOutput(ofImage &outImage,const ofRectangle &bounds)const{
    if (nodes.size() == 0) {
        return;
    }
    CIImage *finalImage = nodes[0].filter->getInput();
    if (nodes[0].state == true) {
        finalImage = nodes[0].filter->getOutput();
    }
    for (int i = 1; i < nodes.size(); i++) {
        if (nodes[i].state == true) {
            nodes[i].filter->setInput(finalImage);
            finalImage = nodes[i].filter->getOutput();
        }
    }
    GLuint width = bounds.width;
    GLuint height = bounds.height;
    CGRect inRect = CGRectMake(0, 0, width, height);
    CGRect fromRect = CGRectMake(bounds.x,bounds.y,bounds.width,bounds.height);
    
    NSOpenGLContext* previousContext = [NSOpenGLContext currentContext];
    [ofxCIFilter::_glContext makeCurrentContext];
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

    [ofxCIFilter::_context drawImage:finalImage inRect:inRect fromRect:fromRect];
    
    GLubyte *data = new GLubyte[width * height * 4];
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
    glDeleteRenderbuffers(1, &renderbuffer);
    glDeleteFramebuffers(1,&framebuffer);
    
    [previousContext makeCurrentContext];
    outImage.setFromPixels(data, width, height, OF_IMAGE_COLOR_ALPHA);
    delete[] data;

}
