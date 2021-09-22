#include <QString>
#include "config.h"

const QString Config::updaterUrl = "https://github.com/pine64/pinecil-firmware-updater/releases/latest";

const QString Config::deviceName = "Pinecil";
const QString Config::firmwareInfo = "http://pinecil.pine64.org/updater/info.json";
const QString Config::firmwareFolder = "http://pinecil.pine64.org/updater/firmwares/";

const int Config::dfuVID = 0x28E9;
const int Config::dfuPID = 0x0189;
const int Config::dfuAlternate = 0;
const int Config::dfuseAddress = 0x08000000;

