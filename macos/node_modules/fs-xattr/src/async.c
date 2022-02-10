#include <assert.h>
#include <errno.h>
#include <stdlib.h>
#include <sys/xattr.h>

#include "error.h"
#include "util.h"

#include "async.h"

typedef struct {
  char* filename;
  char* attribute;
  napi_deferred deferred;
  int e;
  ssize_t value_length;
  char* value;
} XattrGetData;

void xattr_get_execute(napi_env env, void* _data) {
  XattrGetData* data = _data;

#ifdef __APPLE__
  data->value_length = getxattr(data->filename, data->attribute, NULL, 0, 0, 0);
#else
  data->value_length = getxattr(data->filename, data->attribute, NULL, 0);
#endif

  if (data->value_length == -1) {
    data->e = errno;
    return ;
  }

  data->value = malloc((size_t) data->value_length);

#ifdef __APPLE__
  data->value_length = getxattr(data->filename, data->attribute, data->value, (size_t) data->value_length, 0, 0);
#else
  data->value_length = getxattr(data->filename, data->attribute, data->value, (size_t) data->value_length);
#endif

  if (data->value_length == -1) {
    data->e = errno;
    return ;
  }
}

void xattr_get_complete(napi_env env, napi_status status, void* _data) {
  XattrGetData* data = _data;

  free(data->filename);
  free(data->attribute);

  if (data->value_length == -1) {
    napi_value error;
    assert(create_xattr_error(env, data->e, &error) == napi_ok);
    assert(napi_reject_deferred(env, data->deferred, error) == napi_ok);
    return;
  }

  napi_value buffer;
  assert(napi_create_buffer_copy(env, data->value_length, data->value, NULL, &buffer) == napi_ok);
  assert(napi_resolve_deferred(env, data->deferred, buffer) == napi_ok);

  free(_data);
}

napi_value xattr_get(napi_env env, napi_callback_info info) {
  size_t argc = 2;
  napi_value args[2];
  assert(napi_get_cb_info(env, info, &argc, args, NULL, NULL) == napi_ok);

  XattrGetData* data = malloc(sizeof(XattrGetData));

  size_t filename_length;
  assert(napi_get_value_string_utf8(env, args[0], NULL, 0, &filename_length) == napi_ok);
  data->filename = malloc(filename_length + 1);
  assert(napi_get_value_string_utf8(env, args[0], data->filename, filename_length + 1, NULL) == napi_ok);

  size_t attribute_length;
  assert(napi_get_value_string_utf8(env, args[1], NULL, 0, &attribute_length) == napi_ok);
  data->attribute = malloc(attribute_length + 1);
  assert(napi_get_value_string_utf8(env, args[1], data->attribute, attribute_length + 1, NULL) == napi_ok);

  napi_value promise;
  assert(napi_create_promise(env, &data->deferred, &promise) == napi_ok);

  napi_value work_name;
  assert(napi_create_string_utf8(env, "fs-xattr:get", NAPI_AUTO_LENGTH, &work_name) == napi_ok);

  napi_async_work work;
  assert(napi_create_async_work(env, NULL, work_name, xattr_get_execute, xattr_get_complete, (void*) data, &work) == napi_ok);

  assert(napi_queue_async_work(env, work) == napi_ok);

  return promise;
}

typedef struct {
  char* filename;
  char* attribute;
  napi_deferred deferred;
  int e;
  ssize_t value_length;
  char* value;
} XattrSetData;

void xattr_set_execute(napi_env env, void* _data) {
  XattrSetData* data = _data;

#ifdef __APPLE__
  int res = setxattr(data->filename, data->attribute, data->value, data->value_length, 0, 0);
#else
  int res = setxattr(data->filename, data->attribute, data->value, data->value_length, 0);
#endif

  if (res == -1) {
    data->e = errno;
  } else {
    data->e = 0;
  }
}

void xattr_set_complete(napi_env env, napi_status status, void* _data) {
  XattrSetData* data = _data;

  free(data->filename);
  free(data->attribute);

  if (data->e != 0) {
    napi_value error;
    assert(create_xattr_error(env, data->e, &error) == napi_ok);
    assert(napi_reject_deferred(env, data->deferred, error) == napi_ok);
    return;
  }

  napi_value undefined;
  assert(napi_get_undefined(env, &undefined) == napi_ok);
  assert(napi_resolve_deferred(env, data->deferred, undefined) == napi_ok);

  free(_data);
}

napi_value xattr_set(napi_env env, napi_callback_info info) {
  size_t argc = 3;
  napi_value args[3];
  assert(napi_get_cb_info(env, info, &argc, args, NULL, NULL) == napi_ok);

  XattrSetData* data = malloc(sizeof(XattrSetData));

  size_t filename_length;
  assert(napi_get_value_string_utf8(env, args[0], NULL, 0, &filename_length) == napi_ok);
  data->filename = malloc(filename_length + 1);
  assert(napi_get_value_string_utf8(env, args[0], data->filename, filename_length + 1, NULL) == napi_ok);

  size_t attribute_length;
  assert(napi_get_value_string_utf8(env, args[1], NULL, 0, &attribute_length) == napi_ok);
  data->attribute = malloc(attribute_length + 1);
  assert(napi_get_value_string_utf8(env, args[1], data->attribute, attribute_length + 1, NULL) == napi_ok);

  assert(napi_get_buffer_info(env, args[2], (void**) &data->value, (size_t*) &data->value_length) == napi_ok);

  napi_value promise;
  assert(napi_create_promise(env, &data->deferred, &promise) == napi_ok);

  napi_value work_name;
  assert(napi_create_string_utf8(env, "fs-xattr:set", NAPI_AUTO_LENGTH, &work_name) == napi_ok);

  napi_async_work work;
  assert(napi_create_async_work(env, NULL, work_name, xattr_set_execute, xattr_set_complete, (void*) data, &work) == napi_ok);

  assert(napi_queue_async_work(env, work) == napi_ok);

  return promise;
}

typedef struct {
  char* filename;
  napi_deferred deferred;
  int e;
  ssize_t result_length;
  char* result;
} XattrListData;

void xattr_list_execute(napi_env env, void* _data) {
  XattrListData* data = _data;

#ifdef __APPLE__
  data->result_length = listxattr(data->filename, NULL, 0, 0);
#else
  data->result_length = listxattr(data->filename, NULL, 0);
#endif

  if (data->result_length == -1) {
    data->e = errno;
    return ;
  }

  data->result = (char *) malloc((size_t) data->result_length);

#ifdef __APPLE__
  data->result_length = listxattr(data->filename, data->result, (size_t) data->result_length, 0);
#else
  data->result_length = listxattr(data->filename, data->result, (size_t) data->result_length);
#endif

  if (data->result_length == -1) {
    data->e = errno;
    return ;
  }
}

void xattr_list_complete(napi_env env, napi_status status, void* _data) {
  XattrListData* data = _data;

  free(data->filename);

  if (data->result_length == -1) {
    napi_value error;
    assert(create_xattr_error(env, data->e, &error) == napi_ok);
    assert(napi_reject_deferred(env, data->deferred, error) == napi_ok);
    return;
  }

  napi_value array;
  assert(split_string_array(env, data->result, (size_t) data->result_length, &array) == napi_ok);
  assert(napi_resolve_deferred(env, data->deferred, array) == napi_ok);

  free(data->result);
  free(_data);
}

napi_value xattr_list(napi_env env, napi_callback_info info) {
  size_t argc = 1;
  napi_value args[1];
  assert(napi_get_cb_info(env, info, &argc, args, NULL, NULL) == napi_ok);

  XattrListData* data = malloc(sizeof(XattrListData));

  size_t filename_length;
  assert(napi_get_value_string_utf8(env, args[0], NULL, 0, &filename_length) == napi_ok);
  data->filename = malloc(filename_length + 1);
  assert(napi_get_value_string_utf8(env, args[0], data->filename, filename_length + 1, NULL) == napi_ok);

  napi_value promise;
  assert(napi_create_promise(env, &data->deferred, &promise) == napi_ok);

  napi_value work_name;
  assert(napi_create_string_utf8(env, "fs-xattr:list", NAPI_AUTO_LENGTH, &work_name) == napi_ok);

  napi_async_work work;
  assert(napi_create_async_work(env, NULL, work_name, xattr_list_execute, xattr_list_complete, (void*) data, &work) == napi_ok);

  assert(napi_queue_async_work(env, work) == napi_ok);

  return promise;
}

typedef struct {
  char* filename;
  char* attribute;
  napi_deferred deferred;
  int e;
} XattrRemoveData;

void xattr_remove_execute(napi_env env, void* _data) {
  XattrRemoveData* data = _data;

#ifdef __APPLE__
  int res = removexattr(data->filename, data->attribute, 0);
#else
  int res = removexattr(data->filename, data->attribute);
#endif

  if (res == -1) {
    data->e = errno;
  } else {
    data->e = 0;
  }
}

void xattr_remove_complete(napi_env env, napi_status status, void* _data) {
  XattrRemoveData* data = _data;

  free(data->filename);
  free(data->attribute);

  if (data->e != 0) {
    napi_value error;
    assert(create_xattr_error(env, data->e, &error) == napi_ok);
    assert(napi_reject_deferred(env, data->deferred, error) == napi_ok);
    return;
  }

  napi_value undefined;
  assert(napi_get_undefined(env, &undefined) == napi_ok);
  assert(napi_resolve_deferred(env, data->deferred, undefined) == napi_ok);

  free(_data);
}

napi_value xattr_remove(napi_env env, napi_callback_info info) {
  size_t argc = 2;
  napi_value args[2];
  assert(napi_get_cb_info(env, info, &argc, args, NULL, NULL) == napi_ok);

  XattrRemoveData* data = malloc(sizeof(XattrRemoveData));

  size_t filename_length;
  assert(napi_get_value_string_utf8(env, args[0], NULL, 0, &filename_length) == napi_ok);
  data->filename = malloc(filename_length + 1);
  assert(napi_get_value_string_utf8(env, args[0], data->filename, filename_length + 1, NULL) == napi_ok);

  size_t attribute_length;
  assert(napi_get_value_string_utf8(env, args[1], NULL, 0, &attribute_length) == napi_ok);
  data->attribute = malloc(attribute_length + 1);
  assert(napi_get_value_string_utf8(env, args[1], data->attribute, attribute_length + 1, NULL) == napi_ok);

  napi_value promise;
  assert(napi_create_promise(env, &data->deferred, &promise) == napi_ok);

  napi_value work_name;
  assert(napi_create_string_utf8(env, "fs-xattr:remove", NAPI_AUTO_LENGTH, &work_name) == napi_ok);

  napi_async_work work;
  assert(napi_create_async_work(env, NULL, work_name, xattr_remove_execute, xattr_remove_complete, (void*) data, &work) == napi_ok);

  assert(napi_queue_async_work(env, work) == napi_ok);

  return promise;
}
