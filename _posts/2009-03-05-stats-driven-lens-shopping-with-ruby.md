---
layout: post
title: Stats-driven Lens Shopping with Ruby
date: 2009-03-05
comments: true
tags: [Scripts, Ruby, Tips, Programming]
---

I developed the script `photo_stats.rb` to move through date-based folders of photos, and grab EXIF data (thanks to the [exifr gem](http://exifr.rubyforge.org/)) for each photo. The script calculates the mean focal distance of all the photos, sums photos at the widest focal distance (18mm), maximum distance (200mm), and those in the bottom (18.0-46.0mm) and top (154.0-200.0mm) quarter of the focal range.

If you have a similar directory structure (or don't mind tweaking the script), this script should work for your photos too. Remember to install the exifr gem first `gem install exifr`. 

From my own favorite photos from the trip, I concluded that I don't shoot at a lot of focal lengths, so I'd rather have a lens with less range that was optically superior.

```ruby
#!/usr/bin/env ruby
# photo_stats.rb
# (c) 2009 Andy Atkinson
require 'rubygems'
require 'find'
require 'exifr'
class Array
  def sum; inject( nil ) { |sum,x| sum ? sum+x : x }; end;
  def mean; sum / size; end; 
end

# Run $ruby photo_stats.rb in a directory that contains
# subdirectories in this format: /2009_02_02/IMG_1668.JPG and
# compute some focal length stats about all the files
photos = []
Find.find('./') do |file|
  next unless file =~ /(\/\d{4}_\d{2}_\d{2}\/IMG_\d{4}.JPG)/
  filename = file.gsub(/(\/\d{4}_\d{2}_\d{2}\/IMG_\d{4}.JPG)/, '\1')
  photos << EXIFR::JPEG.new(filename).focal_length.to_f
end

mean = photos.mean.round
means = photos.select{|p| (mean-5..mean+5).include?(p) }.length
mins = photos.select{|p| p == photos.min}.length
maxes = photos.select{|p| p == photos.max}.length
bq_range = (photos.min..((photos.max-photos.min)*(1.0/4)).round.to_f)
bottom_quarter = photos.select{|p| bq_range.include?(p)}.length
tq_range = ((photos.max-((photos.max-photos.min)*(1.0/4)).round.to_f)..photos.max)
top_quarter = photos.select{|p| tq_range.include?(p)}.length
```

## Focal length results for 240 photos
* 72 photos at minimum focal length of 18.0mm
* 3 photos at maximum focal length of 200.0mm
* 152 photos in bottom quarter focal distance 18.0-46.0mm
* 8 photos in top quarter focal distance 154.0-200.0mm
* 27 photos +/-5mm of overall mean focal length of 45mm

Most of the photos were in the 18-46 range! Ruby is a great language for scripting and conducting these kinds of experiments.
