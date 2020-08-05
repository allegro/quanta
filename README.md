# Quanta - image optimization service

![test](https://github.com/allegro/quanta/workflows/test/badge.svg)

Quanta is a microservice for JPEG image optimizations built using Swift programming language. It is  similar to other online tools like jpegmini.com, tinypng.com or compressor.io but it is an in-house solution and based on a proven solution like MozJPEG.

Compared with other mozjpeg wrappers, this software has low memory overhead and fast performance, which can help with horizontal scaling with a large number of instances and simultaneous requests.

## More information
We used [Swift](https://swift.org) and [Vapor 3](https://docs.vapor.codes/3.0/) to handle HTTP requests. Check also excellent libraries without which quanta can't work:

 - [mozjpeg](https://github.com/mozilla/mozjpeg)<br>


# Requirements
Quanta requires MozJPEG to be installed on host.

## MacOS
Run `brew install mozjpeg`.

## Linux

You can use the provided script `install-linux-dependencies.sh` to compile and install mozjpeg. Also, follow official documentation in the repository: https://github.com/mozilla/mozjpeg


# Getting started

There are multiple ways to use Quanta to recompress the JPEG file: 

 - REST(-ish) API
 - proxy method
 - via GUI

## REST(-ish) API
Quanta provides REST API. This simple endpoint optimizes image by normal HTTP request and returns image (JPEG).

!!! note
    Quanta always preserves original format. If you send JPEG - you will get (optimized) JPEG.

### Usage

    $ curl -x POST https://quanta.com/optimize/jpg/ -H "Content-Type" \
        --form file=@/tmp/file_to_optimize.jpg
        --form quality=75

According to the table below, as a result, you can get binary data or JSON struct with an error message.

| Status code | Response                      | Headers |
| ----------- | ----------------------------- | ------- |
| 200         | image (binary data)           | ``Content-Type: image/jpeg``<br>``X-Quanta-Ratio: <float>``
| 400         | JSON describes error          | ``Content-Type: application/json``

## Proxy method
The easiest way to integrate with an external system because quanta get an external resource and processing it and send you optimized version.


### Usage

    $ export IMAGE_TO_OPTIMIZE=https://quanta.com/images/quanta.jpg
    $ curl -x GET https://quanta.com/from/?url=$IMAGE_TO_OPTIMIZE&quality=20


## GUI
Simple UI allows you to upload pictures and compare various compressions settings.


## Summary

| Method       | Endpoint                            | Method | Purpose
| ------------ | ----------------------------------- | ------ | -----
| REST-ish API | `/optimize/jpg`                     | POST   | batch processing
| Proxy method | `/from/?url=<url>&quality=<1..100>` | GET    | batch processing<br>or quick preview
| GUI          | -                                   | -      | one-time optimization


# Benchmarks
In this section, you will find information about the performance of quanta.
All samples are from the production of Allegro.

| Name      | Description                                                                | Size               | Preview                          |
| ----------| -------------------------------------------------------------------------- | ------------------ | -------------------------------- |
| Sample #1 | a few colors, headings, irrelevant details                                 | 88 kB (960x252)    | ![sample-1](Resources/Samples/typical_banner_1.jpg)
| Sample #2 | 3 main colors (red, white, black), irrelevant details                      | 88 kB (960x252)    | ![sample-2](Resources/Samples/typical_banner_2.jpg)
| Sample #3 | a text (black on white), details with various colors                       | 508 kB (1600×572)  | ![sample-4](Resources/Samples/typical_banner_3.jpg)


## Performance

### typical_banner_1.jpg
 Quality                 | Optimized file size     | Elapsed time            |
-------------------------|-------------------------|-------------------------|
 65                      | 33 kb                   | 160 ms                  |
 70                      | 37 kb                   | 149 ms                  |
 75                      | 42 kb                   | 158 ms                  |
 80                      | 49 kb                   | 157 ms                  |
 85                      | 58 kb                   | 168 ms                  |
 90                      | 71 kb                   | 262 ms                  |

Size reduction between 16.889% and 61.0427%.


### typical_banner_2.jpg
 Quality                 | Optimized file size     | Elapsed time            |
-------------------------|-------------------------|-------------------------|
 65                      | 30 kb                   | 257 ms                  |
 70                      | 34 kb                   | 258 ms                  |
 75                      | 39 kb                   | 197 ms                  |
 80                      | 47 kb                   | 179 ms                  |
 85                      | 55 kb                   | 175 ms                  |
 90                      | 74 kb                   | 197 ms                  |

Size reduction between 13.4709% and 64.1687%.


### typical_banner_3.jpg
 Quality                 | Optimized file size     | Elapsed time            |
-------------------------|-------------------------|-------------------------|
 65                      | 107 kb                  | 724 ms                  |
 70                      | 117 kb                  | 722 ms                  |
 75                      | 130 kb                  | 724 ms                  |
 80                      | 151 kb                  | 741 ms                  |
 85                      | 175 kb                  | 730 ms                  |
 90                      | 217 kb                  | 791 ms                  |

Size reduction between 55.7364% and 78.1365%.

## Quality comparison
### Details
## JPEG
|               Image              | Original | Quality 75 |
| -------------------------------- | -------- | ---------- |
| typical_banner_from_showbox.jpeg | 77 kB    | 55 kB      |
