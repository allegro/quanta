//
//  cjpeg.h
//  quanta
//
//  Created by Marcin Kliks on 06.06.2018.
//

#ifndef cjpeg_h
#define cjpeg_h
#include <stdio.h>

extern int compressCJPEG(int quality, FILE * from, FILE * to, const char * chroma);

#endif /* cjpeg_h */
