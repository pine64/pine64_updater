#ifndef CONFIG_H
#define CONFIG_H

class Config
{
    public:
        static const QString updaterUrl;

        static const QString deviceName;
        static const QString firmwareInfo;
        static const QString firmwareFolder;

        static const int dfuVID;
        static const int dfuPID;
        static const int dfuAlternate;
        static const int dfuseAddress;
};

#endif /* CONFIG_H */
