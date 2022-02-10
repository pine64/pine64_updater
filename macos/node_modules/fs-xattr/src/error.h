#ifndef LD_ERROR_H
#define LD_ERROR_H

#define NAPI_VERSION 1
#include <node_api.h>

napi_status create_xattr_error(napi_env env, int e, napi_value* result);
napi_status throw_xattr_error(napi_env env, int e);

#endif
