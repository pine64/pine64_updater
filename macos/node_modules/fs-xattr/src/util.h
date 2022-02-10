#ifndef LD_UTIL_H
#define LD_UTIL_H

#include <stddef.h>

#define NAPI_VERSION 1
#include <node_api.h>

napi_status split_string_array(napi_env env, const char *data, size_t length, napi_value* result);

#endif
