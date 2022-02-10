#ifndef LD_SYNC_H
#define LD_SYNC_H

#define NAPI_VERSION 1
#include <node_api.h>

napi_value xattr_get_sync(napi_env env, napi_callback_info info);
napi_value xattr_set_sync(napi_env env, napi_callback_info info);
napi_value xattr_list_sync(napi_env env, napi_callback_info info);
napi_value xattr_remove_sync(napi_env env, napi_callback_info info);

#endif
