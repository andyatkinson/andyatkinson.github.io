---
layout: post
title: Cropping an Image Programmatically
date: 2012-11-28
comments: true
tags: [Tips, Productivity, Programming, CLI]
---

ImageMagick is an image manipulation library that supports the ability to [crop an image programmatically](http://www.imagemagick.org/Usage/crop/#crop). There is a creative aspect to making a crop from an original image. A photo producer may be unhappy with a crop that was chosen automatically. It may make sense to build a tool that provides a nice front-end crop selection experience with ImageMagick performing the actual crop on the server.

This article will assume that having a computer program make a crop from an image is OK. The article gives a little bit of technical detail on how to make a cropped image with ImageMagick.

ImageMagick requires a [geometry argument](http://www.imagemagick.org/script/command-line-processing.php#geometry) for a crop that is comprised of size (width and height) and offset (x and y coordinates). By default the offset is the top left corner of the image. The offset can be changed with the `gravity` option.

Let's say you wanted to take a wide image and make a 4:5 vertical crop of it. A crop could be taken from the left, center, or right side.

This image is a photo I took of some houses in Old Town Alexandria, Virginia. The photo will serve as the test image for this example, used in the commands below as `houses.jpg`. The original image size is 640px wide by 331px tall.

<img src="https://s3.amazonaws.com/webandy-com/blog/houses.jpg" alt="picture of houses in old town alexandria" />

To achieve the new vertical orientation with a 4:5 aspect ratio, with a maximum vertical limit of 331 pixels, and in order to retain the full resolution of the image, we could take a 240x300 slice from somewhere in the image. 240x300 is a 4:5 aspect ratio.

On OS X, after installing ImageMagick with Homebrew (`brew install imagemagick`), running the following command will produce a new file with a crop from the left.

``` bash
convert houses.jpg -crop "240x300+0+0" houses-left.jpg
```
<img src="https://s3.amazonaws.com/webandy-com/blog/houses-left.jpg" alt="picture of houses in old town" />

Instead of the left crop, a crop from the center may be more representative of the original image. For a center crop use the gravity option with a value of `Center`.

``` bash
convert houses.jpg -gravity Center -crop "240x300+0+0" houses-center.jpg
```

<img src="https://s3.amazonaws.com/webandy-com/blog/houses-center.jpg" alt="picture of houses in old town" />

In the center crop output file, we can see the house on the right is not visible at all. A final center crop might move the crop area to the right to get some of the detail from the house on the right, as well as move the crop area down to get more house detail and less sky. The offset is a x and y coordinate pair, so from center, move it over 25 and down 31.

``` bash
convert houses.jpg -gravity Center -crop "240x300+25+31" houses-center-final.jpg
```
<img src="https://s3.amazonaws.com/webandy-com/blog/houses-center-final.jpg" alt="picture of houses in old town" />

The final image is a vertical crop of what was originally a wide aspect ratio, that retains much of the subject matter from the original picture. The final crop favors detail from the houses over the sky, by shifting the viewport down and showing a bit of each house on either side of the center house.
