#ifndef LD_ASYNC_H
#define LD_ASYNC_H

#define NAPI_VERSION 1
#include <node_api.h>

napi_value xattr_get(napi_env env, napi_callback_info info);
napi_value xattr_set(napi_env env, napi_callback_info info);
napi_value xattr_list(napi_env env, napi_callback_info info);
napi_value xattr_remove(napi_env env, napi_callback_info info);

#endif
