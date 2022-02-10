#include <string.h>

#include "util.h"

napi_status split_string_array(napi_env env, const char *data, size_t length, napi_value* result) {
  napi_status status;

  napi_value array;
  status = napi_create_array(env, &array);
  if (status != napi_ok) return status;

  uint32_t array_position = 0;
  size_t value_position = 0;

  while (value_position < length) {
    size_t item_length = strlen(data + value_position);

    napi_value item_string;
    status = napi_create_string_utf8(env, data + value_position, item_length, &item_string);
    if (status != napi_ok) return status;

    status = napi_set_element(env, array, array_position, item_string);
    if (status != napi_ok) return status;

    value_position += item_length + 1;
    array_position += 1;
  }

  napi_value length_number;
  status = napi_create_uint32(env, array_position, &length_number);
  if (status != napi_ok) return status;

  status = napi_set_named_property(env, array, "length", length_number);
  if (status != napi_ok) return status;

  *result = array;
  return napi_ok;
}
