#include <assert.h>

#define NAPI_VERSION 1
#include <node_api.h>

#include "async.h"
#include "sync.h"

static napi_value Init(napi_env env, napi_value exports) {
  napi_value result;
  assert(napi_create_object(env, &result) == napi_ok);

  napi_value get_fn;
  assert(napi_create_function(env, "get", NAPI_AUTO_LENGTH, xattr_get, NULL, &get_fn) == napi_ok);
  assert(napi_set_named_property(env, result, "get", get_fn) == napi_ok);
  napi_value set_fn;
  assert(napi_create_function(env, "set", NAPI_AUTO_LENGTH, xattr_set, NULL, &set_fn) == napi_ok);
  assert(napi_set_named_property(env, result, "set", set_fn) == napi_ok);
  napi_value list_fn;
  assert(napi_create_function(env, "list", NAPI_AUTO_LENGTH, xattr_list, NULL, &list_fn) == napi_ok);
  assert(napi_set_named_property(env, result, "list", list_fn) == napi_ok);
  napi_value remove_fn;
  assert(napi_create_function(env, "remove", NAPI_AUTO_LENGTH, xattr_remove, NULL, &remove_fn) == napi_ok);
  assert(napi_set_named_property(env, result, "remove", remove_fn) == napi_ok);

  napi_value get_sync_fn;
  assert(napi_create_function(env, "getSync", NAPI_AUTO_LENGTH, xattr_get_sync, NULL, &get_sync_fn) == napi_ok);
  assert(napi_set_named_property(env, result, "getSync", get_sync_fn) == napi_ok);
  napi_value set_sync_fn;
  assert(napi_create_function(env, "setSync", NAPI_AUTO_LENGTH, xattr_set_sync, NULL, &set_sync_fn) == napi_ok);
  assert(napi_set_named_property(env, result, "setSync", set_sync_fn) == napi_ok);
  napi_value list_sync_fn;
  assert(napi_create_function(env, "listSync", NAPI_AUTO_LENGTH, xattr_list_sync, NULL, &list_sync_fn) == napi_ok);
  assert(napi_set_named_property(env, result, "listSync", list_sync_fn) == napi_ok);
  napi_value remove_sync_fn;
  assert(napi_create_function(env, "removeSync", NAPI_AUTO_LENGTH, xattr_remove_sync, NULL, &remove_sync_fn) == napi_ok);
  assert(napi_set_named_property(env, result, "removeSync", remove_sync_fn) == napi_ok);

  return result;
}

NAPI_MODULE(NODE_GYP_MODULE_NAME, Init)
