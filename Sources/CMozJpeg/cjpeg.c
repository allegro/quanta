#include "cdjpeg.h"

/**

 This is quanta's main compres function inspired by `cjpeg` commandline app.
 We've chosen low-level API, and not tjCompress2 / tjDecompress turbojpeg API
 since these API's don't call `set_quality_ratings` function.

 We want to have more control over chroma-subsampling, because it makes a *huge*
 difference in quality for sharp, yellow, orange, and text images.

 @chroma - one of "1x1, "2x1", "2x2"
 if specified, overrides chroma subsampling, which is otherwise auto-set.
 auto-set algorithm:
 - for quality 80 ... 90 "2x1" is used, and for >= 90, "1x1" is used
 **/


extern int compressCJPEG(int quality, FILE * input_file, FILE * output_file, const char * chroma) {

    struct jpeg_compress_struct cinfo;
    struct jpeg_error_mgr jerr;
    cjpeg_source_ptr src_mgr;
    JDIMENSION num_scanlines;

    unsigned char *outbuffer = NULL;
    unsigned long outsize = 0;

    unsigned char *inbuffer = NULL;
    unsigned long insize = 0;

    cinfo.err = jpeg_std_error(&jerr);
    cinfo.optimize_coding = TRUE;
    cinfo.smoothing_factor = 1;

    jpeg_create_compress(&cinfo);

    cinfo.in_color_space = JCS_RGB; /* arbitrary guess */

    src_mgr = jinit_read_jpeg(&cinfo);

    src_mgr->input_file = input_file;
    (*src_mgr->start_input) (&cinfo, src_mgr);


    jpeg_set_defaults(&cinfo);
    jpeg_default_colorspace(&cinfo);

    jpeg_stdio_dest(&cinfo, output_file);

    char quality_str[10];
    sprintf(quality_str, "%d", quality);

    set_quality_ratings(&cinfo, quality_str, 0);

    if (chroma != NULL) {
        set_sample_factors(&cinfo, chroma);
    }

    jpeg_start_compress(&cinfo, TRUE);

    // we assume it is JPEG source

    jpeg_saved_marker_ptr marker;

    /* In the current implementation, we don't actually need to examine the
     * option flag here; we just copy everything that got saved.
     * But to avoid confusion, we do not output JFIF and Adobe APP14 markers
     * if the encoder library already wrote one.
     */
    for (marker = src_mgr->marker_list; marker != NULL; marker = marker->next) {
        if (cinfo.write_JFIF_header &&
            marker->marker == JPEG_APP0 &&
            marker->data_length >= 5 &&
            GETJOCTET(marker->data[0]) == 0x4A &&
            GETJOCTET(marker->data[1]) == 0x46 &&
            GETJOCTET(marker->data[2]) == 0x49 &&
            GETJOCTET(marker->data[3]) == 0x46 &&
            GETJOCTET(marker->data[4]) == 0)
            continue;                       /* reject duplicate JFIF */
        if (cinfo.write_Adobe_marker &&
            marker->marker == JPEG_APP0+14 &&
            marker->data_length >= 5 &&
            GETJOCTET(marker->data[0]) == 0x41 &&
            GETJOCTET(marker->data[1]) == 0x64 &&
            GETJOCTET(marker->data[2]) == 0x6F &&
            GETJOCTET(marker->data[3]) == 0x62 &&
            GETJOCTET(marker->data[4]) == 0x65)
            continue;                       /* reject duplicate Adobe */
        jpeg_write_marker(&cinfo, marker->marker, marker->data,
                          marker->data_length);
    }


    /* Process data */
    while (cinfo.next_scanline < cinfo.image_height) {
        num_scanlines = (*src_mgr->get_pixel_rows) (&cinfo, src_mgr);
#if JPEG_RAW_READER
        (void) jpeg_write_raw_data(&cinfo, src_mgr->plane_pointer, num_scanlines);

#else
        (void) jpeg_write_scanlines(&cinfo, src_mgr->buffer, num_scanlines);
#endif

    }
    (*src_mgr->finish_input) (&cinfo, src_mgr);
    jpeg_finish_compress(&cinfo);
    jpeg_destroy_compress(&cinfo);

    if (input_file != stdin)
        fclose(input_file);
    if (output_file != stdout && output_file != NULL)
        fclose(output_file);
}
