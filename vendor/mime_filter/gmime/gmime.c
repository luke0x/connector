// Copyright 2004-2007 Joyent Inc.
// 
// Redistribution and/or modification of this code is governed
// by either the GPLv2 or Joyent Commercial Software licenses.
// 
// Report issues and contribute at http://dev.joyent.com/
// 
// $Id$

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#include <glib.h>
#include <glib/gstdio.h>

#include <gmime/gmime.h>


static void	write_part(GMimeObject *part);

int level     = 0; // globals RULE
int text_only = 0;

static void
display_image(GMimeObject *part)
{
	const char *disposition;
	disposition = g_mime_part_get_content_disposition(GMIME_PART(part));
	if (disposition == NULL)
		return;
		
	if (strcmp(g_mime_part_get_content_disposition(GMIME_PART(part)), "inline") == 0) {
		printf("%%INLINE-%d%%\n", level);
	}
}

static void
display_part(GMimeObject *part, const GMimeContentType *ct)
{
	GMimeStream *ostream, *fstream;
	GMimeFilter *basic;
	GMimeDataWrapper *content;
	GMimeFilter *charset, *html;
	
	GMimePartEncodingType encoding;
		
	encoding = g_mime_part_get_encoding(GMIME_PART(part));
	
	fstream = g_mime_stream_file_new(stdout);
	ostream = g_mime_stream_filter_new_with_stream(fstream);
	g_mime_stream_unref(fstream);
	
	/* Encoding filter, always on */
	if (charset = g_mime_filter_charset_new(g_mime_content_type_get_parameter(ct, "charset"), "utf-8")) {
		g_mime_stream_filter_add(GMIME_STREAM_FILTER(ostream), charset);
		g_object_unref(charset);
	}
	
	if (g_mime_content_type_is_type(ct, "text", "plain")) {
		if (text_only == 0) {
			html = g_mime_filter_html_new (
					       	GMIME_FILTER_HTML_CONVERT_SPACES |
					       	GMIME_FILTER_HTML_CONVERT_URLS |
					       	GMIME_FILTER_HTML_MARK_CITATION |
					       	GMIME_FILTER_HTML_CITE, 0);
			g_mime_stream_filter_add(GMIME_STREAM_FILTER(ostream), html);
			g_object_unref(html);
		}
							
		content = g_mime_part_get_content_object(GMIME_PART(part));
		g_mime_data_wrapper_write_to_stream(content, ostream);
		g_mime_stream_flush(ostream);
		
		g_object_unref(content);
		// GMimeFilterBasic (base64, quopri)
		// GMimeFilterCharset
		// GMimeFilterHTML
		// GMimeFilterEnriched (text/enriched, text/rtf)
	} else if (g_mime_content_type_is_type(ct, "text", "html")) {
		content = g_mime_part_get_content_object(GMIME_PART(part));
		g_mime_data_wrapper_write_to_stream(content, ostream);
		g_mime_stream_flush(ostream);

		g_object_unref(content);
	} else if (strcmp(ct->type, "image") == 0) {
		display_image(part);
	}
}

static gint
find_part_of_type(GMimeObject *part, GMimeContentType *fct)
{
	const GMimeContentType *ct;
	ct = g_mime_object_get_content_type(part);
	if (g_mime_content_type_is_type(ct, fct->type, fct->subtype)) {
		return 0;
	}
	return -1;
}

static void
choose_alternative(GMimeObject *part)
{
	GList *l, *fpart;
	l = GMIME_MULTIPART(part)->subparts;
	// Look for a preferred part in this order:
	// * multipart/relative
	// * text/html
	// * text/plain
	if (fpart = g_list_find_custom(l, g_mime_content_type_new("multipart", "related"), (GCompareFunc)find_part_of_type)) {
		choose_alternative(fpart->data);
		return;
	}
	if (fpart = g_list_find_custom(l, g_mime_content_type_new("text", "html"), (GCompareFunc)find_part_of_type)) {
		write_part(fpart->data);
		return;
	}	
	if (fpart = g_list_find_custom(l, g_mime_content_type_new("text", "plain"), (GCompareFunc)find_part_of_type)) {
		write_part(fpart->data);
		return;
	}
}

static void
write_part(GMimeObject *part)
{
	GList *l;
	const GMimeContentType *ct;
	ct = g_mime_object_get_content_type(GMIME_OBJECT(part));
	
	if (GMIME_IS_MULTIPART(part)) {
		if (g_mime_content_type_is_type(ct, "multipart", "alternative")) {
			choose_alternative(part);
			level += g_list_length(GMIME_MULTIPART(part)->subparts);
		} else {
			l = GMIME_MULTIPART(part)->subparts;
			while (l != NULL) {
				write_part(l->data);
				l = l->next;
				level++;
			}
		}
	} else if (GMIME_IS_MESSAGE_PART(part)) {
	} else if (GMIME_IS_PART(part)) {
		display_part(part, ct);
	}
}

int main (int argc, const char* argv[])
{
	GMimeMessage *message;
	GMimeParser  *parser;
	GMimeStream  *stream;
	const char   *file = argv[1];

	int fd;

	if (argc < 2) {
		printf("No file name given\n");
		return 1;
	}
	
	if (argc == 3) {
		text_only = 1;
		file = argv[2];
	}
	
	g_mime_init(0);
	g_mime_iconv_init();
	
	if ((fd = open(file, O_RDONLY)) == -1) {
		printf("Error opening file %s\n", file);
		return 1;
	}
	
	stream = g_mime_stream_fs_new(fd);
	parser = g_mime_parser_new_with_stream(stream);
	
	g_mime_parser_set_scan_from(parser, FALSE);
	g_object_unref(stream);
	
	message = g_mime_parser_construct_message(parser);
	g_object_unref(parser);
	
	if (message) {
		write_part(message->mime_part);
	} else {
		printf("Error constructing message\n");
		return 1;
	}
	
	g_mime_iconv_shutdown();
	return 0;
}