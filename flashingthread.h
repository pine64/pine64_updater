#ifndef FLASHINGTHREAD_H
#define FLASHINGTHREAD_H

#include <QThread>

class FlashingThread : public QThread
{
    Q_OBJECT
public:
    FlashingThread(QObject *parent = nullptr, bool driverMissing = false, QString firmwarePath = "")
     : QThread(parent), driverMissing(driverMissing), firmwarePath(firmwarePath) {}
    // QThread interface
protected:
    void run();
private:
    bool driverMissing;
    QString firmwarePath;

signals:
    void successed();
    void failed();
    void consoleData(QString data);
    void consoleErrorData(QString data);
};

#endif // FLASHINGTHREAD_H
