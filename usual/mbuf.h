
/*
 * Safe and easy access to memory buffer.
 */

#ifndef _USUAL_MBUF_H_
#define _USUAL_MBUF_H_

#include <usual/base.h>

#include <stdlib.h>
#include <string.h>

struct MBuf {
	uint8_t *data;
	unsigned read_pos;
	unsigned write_pos;
	unsigned alloc_len;
	bool reader;
	bool fixed;
};

/*
 * Init functions.
 */

static inline void mbuf_init_fixed_reader(struct MBuf *buf, const void *ptr, unsigned len)
{
	buf->data = (uint8_t *)ptr;
	buf->read_pos = 0;
	buf->write_pos = len;
	buf->alloc_len = len;
	buf->reader = true;
	buf->fixed = true;
}

static inline void mbuf_init_fixed_writer(struct MBuf *buf, void *ptr, unsigned len)
{
	buf->data = (uint8_t *)ptr;
	buf->read_pos = 0;
	buf->write_pos = 0;
	buf->alloc_len = len;
	buf->reader = false;
	buf->fixed = true;
}

static inline void mbuf_init_dynamic(struct MBuf *buf)
{
	buf->data = NULL;
	buf->read_pos = 0;
	buf->write_pos = 0;
	buf->alloc_len = 0;
	buf->reader = false;
	buf->fixed = false;
}

static inline void mbuf_free(struct MBuf *buf)
{
	if (!buf->fixed && buf->data) {
		free(buf->data);
		buf->data = NULL;
		buf->read_pos = buf->write_pos = buf->alloc_len = 0;
	}
}

/*
 * Reset functions.
 */

static inline void mbuf_rewind_reader(struct MBuf *buf)
{
	buf->read_pos = 0;
}

static inline void mbuf_rewind_writer(struct MBuf *buf)
{
	if (!buf->reader) {
		buf->read_pos = 0;
		buf->write_pos = 0;
	}
}

/*
 * Info functions.
 */

static inline unsigned mbuf_avail_for_read(const struct MBuf *buf)
{
	return buf->write_pos - buf->read_pos;
}

static inline unsigned mbuf_avail_for_write(const struct MBuf *buf)
{
	if (!buf->reader && buf->alloc_len > buf->write_pos)
		return buf->alloc_len - buf->write_pos;
	return 0;
}

static inline unsigned mbuf_written(const struct MBuf *buf)
{
	return buf->write_pos;
}

/*
 * Read functions.
 */

_MUSTCHECK
static inline bool mbuf_get_byte(struct MBuf *buf, uint8_t *dst_p)
{
	if (buf->read_pos + 1 > buf->write_pos)
		return false;
	*dst_p = buf->data[buf->read_pos++];
	return true;
}

_MUSTCHECK
static inline bool mbuf_get_bytes(struct MBuf *buf, unsigned len, const uint8_t **dst_p)
{
	if (buf->read_pos + len > buf->write_pos)
		return false;
	*dst_p = buf->data + buf->read_pos;
	buf->read_pos += len;
	return true;
}

_MUSTCHECK
static inline bool mbuf_get_string(struct MBuf *buf, const char **dst_p)
{
	const char *res = (char *)buf->data + buf->read_pos;
	const uint8_t *nul = memchr(res, 0, mbuf_avail_for_read(buf));
	if (!nul)
		return false;
	*dst_p = res;
	buf->read_pos = nul + 1 - buf->data;
	return true;
}

/*
 * Write functions.
 */

_MUSTCHECK
bool mbuf_make_room(struct MBuf *buf, unsigned len);

_MUSTCHECK
static inline bool mbuf_write_byte(struct MBuf *buf, uint8_t val)
{
	if (buf->write_pos + 1 > buf->alloc_len
	    && !mbuf_make_room(buf, 1))
		return false;
	buf->data[buf->write_pos++] = val;
	return true;
}

_MUSTCHECK
static inline bool mbuf_write(struct MBuf *buf, const void *ptr, unsigned len)
{
	if (buf->write_pos + len > buf->alloc_len
	    && !mbuf_make_room(buf, len))
		return false;
	memcpy(buf->data + buf->write_pos, ptr, len);
	buf->write_pos += len;
	return true;
}

/* writes full contents of another mbuf, without touching it */
_MUSTCHECK
static inline bool mbuf_write_raw_mbuf(struct MBuf *dst, struct MBuf *src)
{
	return mbuf_write(dst, src->data, src->write_pos);
}

_MUSTCHECK
static inline bool mbuf_fill(struct MBuf *buf, uint8_t byte, unsigned len)
{
	if (buf->write_pos + len > buf->alloc_len
	    && !mbuf_make_room(buf, len))
		return false;
	memset(buf->data + buf->write_pos, byte, len);
	buf->write_pos += len;
	return true;
}

#endif

