
#include <nan.h>
#include <node.h>
#include <v8.h>

#ifdef __APPLE__
#include "impl-apple.cc"
#else
#error This platform is not implemented yet
#endif

using v8::FunctionTemplate;

NAN_MODULE_INIT(Initialize) {
  Nan::Set(target, Nan::New("getVolumeName").ToLocalChecked(),
    Nan::GetFunction(Nan::New<FunctionTemplate>(MethodGetVolumeName)).ToLocalChecked());
}

NODE_MODULE(volume, Initialize)
