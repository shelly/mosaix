# Mosaix - An iOS Photo Mosaic App
### Nathan Eliason & Shelly Bensal

## Summary
______

We will implement an iOS application which uses the Metal framework to generate photo mosaics in parallel on-demand. Using the photos already in the device's Photo Library, Mosaix will reconstruct the photo by selecting photos which match in color, shape, and contrast and placing them in a grid pattern representing the original image.

<p align="center">
  <img width="350" src="http://download2.artensoft.com/artensoft_com/ArtensoftPhotoMosaicWizard/gallery/flower_cat_1920.jpg">
</p>

## Background
______
Our application will be a Swift mobile app with a fairly simple user interface; the user will select the desired image (we'll refer to it as the _reference photo_) and adjust a few settings (grid size, image cropping, etc.). At this point, the application will reassemble the selected image (into the _composite photo_) of the other images in the users' libraries, presenting the user with the _composite_ as a final result.

The most important -- and most parallelizable -- aspect of this project is the fitting of images to different sections of the reference photo. This operation is highly parallelizable as sections of the reference photo are fairly independent.


## The Challenge
______
 - While each square section of the reference photo is in itself independent, communication between selections of adjacent squares are important for flow in the overall image -- it will be important to select photos that don't contrast highly along the seams between photos in order for the reference photo to be visible from the composite image.
 - Additionally, communication between selections of similar colors, shapes, and contrast patterns is incredibly important as we are choosing not to use the same source photo twice within the composite image. For example, a reference photo with a solid blue sky could very easily match the same photo across a major portion of the gridspace if there was no communication between selection in that region.


## Resources
______
We'll be writing the app from scratch in Swift, with the exception of our usage of the Metal framework for low-level GPU access. We're still researching the algorithmic approach to this problem and will likely implement numerous known photo-processing algorithms in our attempt to find the most efficient solution.


## Goals & Deliverables
______

After creating the application that can display composite images based on the algorithmic selection and the general user interface, we'll implement the selection algorithm twice -- once naively on Metal and once as our optimized alternative. As we refine our parallel algorithm according to the tiered goals below, we'll adjust the naive solution so that the two solve the same problem (ex: duplicate source image avoidance). We'll present the user with a toggle-switch to change between the naive solution and our optimized algorithm within the app.


#### Plan to Achieve
 - Full graphic user interface with automatic photo library access and an in-app camera and photo selector.
 - Automatic photo selection in parallel on the Metal framework which provides a composite photo through which the reference photo is recognizable.
 - Adjustable grid size and final quality -- letting the user select how large each source image is framed within the final composite photo how picky the algorithm is in its selection.
 - Pre-processing of the device's Photo Library that reduces complexity and time of the generation of each individual mosaic.


#### Hope to Achieve
 - Source photo cropping and resizing for framing within the composite image.
 - Imperfect grids (patchwork patterns for selection).
 - We hope to achieve performance that improves upon existing solutions in the app store. While there are a few apps already that perform similar functions to Mosaix, they consume 30-40s per image to finish processing (depending on grid size and quality).
 - Video processing (frame-by-frame mosaic generation and fluid playback).
 - A job queue for videos and large photos.

#### Demo
 - We will be able to demonstrate the app live on an iPhone. We can demonstrate Mosaix by taking a picture live and have the application generate a composite mosaic of that image on the spot.

## Platform Choice
______
Mosaix makes the most sense on a mobile device because that's the platform on which a majority of our everday photos are taken and stored. Creating a mobile app makes it easy for the end user to take a photo and see a live result, and makes sharing the composite image much simpler. 

In particular, our choice of iOS 10 on iPhone 7 is driven mostly by the inclusion of the Metal framework, which will give us unprecendented low-level access to the GPU on the iPhone 7. Not only was the hardware specifically designed with photo processing in mind, but the software gives us complete control over multi-threading and image processing and a simple way of accessing a library of existing photos.


## Schedule
______

Date | Task
-----|-----
Friday, April 14th | Implement a simple GUI for the application that can access the Photo Library and display composite images according to a naive selection algorithm.
Wednesday, April 19th | A reasonable parallel algorithm for source photo selection implemented on the Metal framework working alongside the naive algorithm for composition.
Tuesday, April 25th | A reasonable parallel algorithm for source photo selection and photo library pre-processing and a user-controllable switch between the two algorithms.
Monday, May 1st | Implement adjustable grid size and composite image quality. Begin work on stretch goal features.
Friday, May 5th | Implement more advanced features and work on stretch goals (source photo adjustments, video processing, imperfect grids, etc.).
Tuesday, May 9th | Complete all functionality of the Mosaix application. Begin work on the project video.
Friday, May 12th | Submit final project and video.
