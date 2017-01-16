#ofxCoreImageFilters
ofxCoreImage Filters allows you to apply Core Image filters on ofImages. See the [Core Image Filter Reference](https://developer.apple.com/library/mac/documentation/graphicsimaging/reference/CoreImageFilterReference/Reference/reference.html) for the full list of available effects.

## Features

* Supports all 173 filters
* Works with openGl 3.2+ and the programmable renderer.

####Performance Note
Compiling for 64 bit gives almost double the frame rate,so consider it if you need the extra performance.You can get a 64 bit version of OpenFrameworks here <https://github.com/NickHardeman/openframeworks_osx_64>

***

##How to use 

####Step 1 Change source files to objective c++

Every source file in which you include "ofxCI.h", must be marked as objective c++. To do this select the file, open the file inspector (option+command + 1) and select objective c++ as the type. Some people might say to change the extension from .cpp to .mm, but this does not always work. 

#### step 2 Setup and configure a filter
calling setup creates the filter and sets it up with default parameters. To see list of filter types look at the file ofxCIConstants.h. For full documentation refer to the [Core Image Filter Reference](https://developer.apple.com/library/mac/documentation/graphicsimaging/reference/CoreImageFilterReference/Reference/reference.html)

```
 ofxCIFilter parallelogram;
 parallelogram.setup(OFX_FILTER_TYPE_PARALLELOGRAM_TILE);
```

call getAvailableSettings() to view parameters

	parallelogram.getAvailableSettings();

getAvailableSettings() will print the name,type,and range of each parameter. Usually any parameters that have the word 'Image' in them are mandatory to set. `parallelogram.getAvailableSettings()` will print the following.

	CIParallelogramTile:
	inputImage          type:ofImage
	inputCenter         type:ofVec2f
	inputAngle          type:float        range: -3.14159 to 3.14159
	inputAcuteAngle     type:float        range: -3.14159 to 3.14159
	inputWidth          type:float        range: 1 to 200

you set the parameters like this

``` 
	ofImage myInput;
    myInput.loadImage("picture.jpg");
    parallelogram.setInputImage(myInput);
    parallelogram.setInputCenter(ofVec2f(123,45));
    parallelogram.set("inputAcuteAngle",1.4f);
    parallelogram.setInputWidth(20.0);
```    
Common parameters like "inputImage" and "inputCenter" have built in functions to set them. For less common parameters like "inputAcuteAngle" you must use the function 



```
ofxCIFilter::set(string parameterName, T value)
```

#### step 3 Get the output of a filter

call `getOutput(const ofImage &outImage)` to get the output image. This function deletes whatever was previously in the outImage and creates a new image.

```
	ofImage outImage;
    parallelogram.getOutput(outImage);
    
    // do whatever you want with outImage
    // ...

```

### Chaining Filters
One way to chain filters is to pass the output of one filter into the input of another. But a more efficient way is to use an ofxCIFilterChain. It is more efficient because it skips the conversion steps between ofImage and CIImage;

Example use of an ofxCIFilterChain.

```
	ofImage input;
    input.loadImage("picture.png");
    
    ofxCIFilter blur;
    ofxCIFilter edges;
    ofxCIFilter gloom;
    
    blur.setup(OFX_FILTER_TYPE_GAUSSIAN_BLUR);
    blur.setInputImage(input);
    edges.setup(OFX_FILTER_TYPE_EDGES);
    gloom.setup(OFX_FILTER_TYPE_GLOOM);

    ofxCIFilterChain chain;
    chain.addFilter(blur);
    chain.addFilter(edges);
    chain.addFilter(gloom);
    
    ofImage output;
    chain.getOutput(output);
```
You only have to set 'inputImage' on the first filter. ofxCIFilterChain only takes a weak reference to the filters so make sure each filter you added is still around in memory when you call getOutput() on the chain.
___
### Credits
Thanks @laserpilot whose [original Core Image addon](https://github.com/laserpilot/ofxCoreImage) served as a foundation






  




