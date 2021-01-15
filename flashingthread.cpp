#include "flashingthread.h"

#include <QProcess>

void FlashingThread::run()
{
    // zadic.exe --vid 0x28E9 --pid 0x0189 --noprompt
    if (this->driverMissing) {
        emit consoleData("WinUSB driver not found. Installing...");
        QProcess zadic;
        QStringList zadicArgs;
        zadicArgs.append("--vid");
        zadicArgs.append("0x28E9");
        zadicArgs.append("--pid");
        zadicArgs.append("0x0189");
        zadicArgs.append("--noprompt");
        connect(&zadic, &QProcess::readyReadStandardOutput, [this, &zadic] {
            emit this->consoleData(zadic.readAllStandardOutput());
        });
        connect(&zadic, &QProcess::readyReadStandardError, [this, &zadic] {
            emit this->consoleErrorData(zadic.readAllStandardError());
        });
        zadic.start("zadic.exe", zadicArgs);
        if (!zadic.waitForFinished(60 * 2 * 1000)) {
            emit consoleErrorData("Launching zadic failed!");
            emit failed();
            return;
        }
        if (zadic.exitCode() != 0) {
            emit consoleErrorData(QString("Zadic exited with error code %1!").arg(zadic.exitCode()));
            emit failed();
            return;
        }
    }
    emit consoleData("Flashing...");
    QProcess dfuUtil;
    QStringList dfuUtilArgs;
    dfuUtilArgs.append("-d");
    dfuUtilArgs.append("28e9:0189");
    dfuUtilArgs.append("-a");
    dfuUtilArgs.append("0");
    dfuUtilArgs.append("-D");
    dfuUtilArgs.append(this->firmwarePath);
    dfuUtilArgs.append("-s");
    dfuUtilArgs.append("0x08000000:mass-erase:force");
    connect(&dfuUtil, &QProcess::readyReadStandardOutput, [this, &dfuUtil] {
        emit this->consoleData(dfuUtil.readAllStandardOutput());
    });
    connect(&dfuUtil, &QProcess::readyReadStandardError, [this, &dfuUtil] {
        emit this->consoleErrorData(dfuUtil.readAllStandardError());
    });
    dfuUtil.start("dfu-util.exe", dfuUtilArgs);
    if (!dfuUtil.waitForFinished(60 * 5 * 1000)) {
        emit consoleErrorData("Launching dfu-util failed!");
        emit failed();
        return;
    }
    if (dfuUtil.exitCode() != 0) {
        emit consoleErrorData(QString("DFU-Util exited with error code %1!").arg(dfuUtil.exitCode()));
        emit failed();
        return;
    }
    emit successed();
}
