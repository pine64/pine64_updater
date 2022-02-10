
#include <Carbon/Carbon.h>
#include <CoreFoundation/CFURL.h>
#include <CoreFoundation/CFString.h>

const char* OSErrDescription(OSErr err) {
  switch (err) {
    case nsvErr: return "Volume not found";
    case ioErr: return "I/O error.";
    case bdNamErr: return "Bad filename or volume name.";
    case mFulErr: return "Memory full (open) or file won't fit (load)";
    case tmfoErr: return "Too many files open.";
    case fnfErr: return "File or directory not found; incomplete pathname.";
    case volOffLinErr: return "Volume is offline.";
    case nsDrvErr: return "No such drive.";
    case dirNFErr: return "Directory not found or incomplete pathname.";
    case tmwdoErr: return "Too many working directories open.";
  }

  return "Could not get volume name";
}

NAN_METHOD(MethodGetVolumeName) {
  Nan::Utf8String aPath(info[0]);

  CFStringRef volumePath = CFStringCreateWithCString(NULL, *aPath, kCFStringEncodingUTF8);
  CFURLRef url = CFURLCreateWithFileSystemPath(NULL, volumePath, kCFURLPOSIXPathStyle, true);

  OSErr err;
  FSRef urlFS;
  FSCatalogInfo urlInfo;
  HFSUniStr255 outString;

  if (CFURLGetFSRef(url, &urlFS) == false) {
    return Nan::ThrowError("Failed to convert URL to file or directory object");
  }

  if ((err = FSGetCatalogInfo(&urlFS, kFSCatInfoVolume, &urlInfo, NULL, NULL, NULL)) != noErr) {
    return Nan::ThrowError(OSErrDescription(err));
  }

  if ((err = FSGetVolumeInfo(urlInfo.volume, 0, NULL, kFSVolInfoNone, NULL, &outString, NULL)) != noErr) {
    return Nan::ThrowError(OSErrDescription(err));
  }

  info.GetReturnValue().Set(Nan::New<v8::String>(outString.unicode, outString.length).ToLocalChecked());
}
