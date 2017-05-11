# Mosaix - An iOS Photo Mosaic App
### Nathan Eliason & Shelly Bensal
<em>Updated May 10th, 2017</em>

## Summary
______

We created an iOS application which uses the Metal framework to generate photo mosaics in parallel, on-demand. Using the photos already in the device's Photo Library, Mosaix reconstructs the reference photo by selecting photos which match in color, shape, and contrast and placing them in a grid pattern representing the original image. _Our iOS app currently exhibits about 20x speedup over the leading photo mosaic applications available in the App Store._

<p align="center">
  <img width="350" height="350" src="https://hunt.blob.core.windows.net/web-images/parallel/dog.jpg">
  <img width="350" height="350" src="https://hunt.blob.core.windows.net/web-images/parallel/mosaic_dog.jpg"><br/>
  <em>A reference and composite comparison generated by our parallel algorithm, chosen to be of "low-quality" and "high grid size" .</em>
</p>

#### Demo
 - We can demonstrate the app live on an iPhone, by taking a picture live and having the application generate a composite mosaic of that image on the spot with both a naive and parallel implementation.

## Background 
______
Our application is a Swift mobile app with a fairly simple user interface; the user selects the desired image (referred to as the _reference photo_) and adjusts the grid size and quality. At this point, the application reassembles the selected image (into the _composite photo_) of the other images in the users' libraries, presenting the user with the _composite_ as a final result.

Our goal was to implement a reasonable approach to transforming photos into a feature vector, apply this transformation efficiently to the entire Photo Library, and then find the minimum difference between the vector of a subsection of our reference photo and the vector of some photo from the photo library so that we can replace it. 

#### Platform Choice & Resources 

Mosaix made the most sense on a mobile device because that's the platform on which a majority of our everyday photos are taken and stored. Creating a mobile app made it easy for the end user to take a photo and see a live result, and made sharing the composite image much simpler. 

In particular, our choice of iOS 10 on iPhone 7 is driven mostly by the inclusion of the Metal framework, which gave us unprecendented low-level access to the GPU on the iPhone 7. Not only was the hardware specifically designed with photo processing in mind, but the software gave us complete control over multi-threading and image processing and a simple way of accessing a library of existing photos.

#### Major Challenges
- We'd never worked with Swift 3 or Metal before, and iOS apps are developed using a unique design paradigm, and custom interfaces and data types with restrictions upon how and when they can be used. For example, photos in the Photo Library are stored as and are accessible only as PHAssets, whereas Metal primarily supports MTLTextures and all transformations performed upon photos had to be upon textures in order to run in the kernel.  
- The iPhone 7 is quad-core, but application usage is restricted, and there is no interface to directly schedule jobs to cores. If an application uses too much power, the application is throttled down, so achieving speedup required a balance between utilizing resources and overreaching our limits. 
- Fetching photos from the Photo Library is bandwidth-bound, and repeatedly accessing photos from it, or even queuing multiple requests for specific photos, caused slowdown and had to be worked around.
- 2GB of RAM meant that holding all (or even a reasonable fraction) of photos from the Photo Library in memory efficiently was not possible, and so batch processing and converting to simplified representations of the photos as soon as possible was necessary. 
<!---
--> 

## Approach 
______

There were two main algorithms we parallelized.
<ol>
  <li><em>Generating a reasonable representation of photos within the Photo Library so that we can efficiently detect what the best match for a particular subsection of our reference photo is.</em>
  
  We did this with a technique we called Ten Point Averaging (derivative of a nine point average system), which split each library photo into a 3x3 grid and found the average R, G, and B values in each subsection, as well as the average R, G, and B values for the entire image. We then created a 30-dimensional feature vector of these 10 numbers x 3 channels, and considered this as our representation of the image for candidate selection.
  </li>
  <li><em>Breaking down the reference photo into sections and choosing a single "best" image to represent each section in the composite image.</em>
  
  To choose a best image, each of the subsections of the reference photo reduce across the feature vectors of all of the photos in the photo library, attempting to identify candidate photos with lower absolute differences between their feature vectors. The resulting best fit is then used to replace that subsection of the photo. 
  </li>
</ol>

<!---
TODO: [BEFORE FRIDAY] Rewrite to better address current approach.
-->
 
## Results
______

<!---
TODO: [BEFORE FRIDAY] Fill in.
-->

#### Features
 - Full graphic user interface with automatic photo library access and an in-app camera and photo selector.
 - Adjustable grid size and final quality -- letting the user select how large each source image is framed within the final composite photo and how picky the algorithm is in its selection.
 - Implemented naive and basic parallel photo selection algorithms.
 - Pre-processing of the device's Photo Library that reduces complexity and time of the generation of each individual mosaic.
 - Performance that improves upon existing solutions in the app store. While there are a few apps already that perform similar functions to Mosaix, they consume 30-40s per image to finish processing (depending on grid size and quality).

## References 
______
- Apple Developer Documentation 

<!---
TODO: [BEFORE FRIDAY] Fill in.
-->

## Work By Each Student 
______

<!---
TODO: [BEFORE FRIDAY] Fill in.
-->
