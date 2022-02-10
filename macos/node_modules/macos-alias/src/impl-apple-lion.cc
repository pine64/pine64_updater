
#include <CoreFoundation/CFURL.h>
#include <CoreFoundation/CFString.h>

using v8::String;
using v8::Exception;
using v8::Local;
using v8::Value;

Local<String> MYCFStringGetV8String(CFStringRef aString) {
  if (aString == NULL) {
    return Nan::EmptyString();
  }

  CFIndex length = CFStringGetLength(aString);
  CFIndex maxSize = CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8);
  char *buffer = (char *) malloc(maxSize);

  if (!CFStringGetCString(aString, buffer, maxSize, kCFStringEncodingUTF8)) {
    return Nan::EmptyString();
  }

  Local<String> result = Nan::New(buffer).ToLocalChecked();
  free(buffer);

  return result;
}

NAN_METHOD(MethodGetVolumeName) {
  Nan::Utf8String aPath(info[0]);

  CFStringRef out;
  CFErrorRef error;

  CFStringRef volumePath = CFStringCreateWithCString(NULL, *aPath, kCFStringEncodingUTF8);
  CFURLRef url = CFURLCreateWithFileSystemPath(NULL, volumePath, kCFURLPOSIXPathStyle, true);

  if(!CFURLCopyResourcePropertyForKey(url, kCFURLVolumeNameKey, &out, &error)) {
    return Nan::ThrowError(MYCFStringGetV8String(CFErrorCopyDescription(error)));
  }

  info.GetReturnValue().Set(MYCFStringGetV8String(out));
}
