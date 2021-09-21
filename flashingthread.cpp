#include "flashingthread.h"
#include "config.h"

#include <QCoreApplication>
#include <QProcess>

void FlashingThread::run()
{
    // zadic.exe --vid 0x28E9 --pid 0x0189 --noprompt
    if (this->driverMissing) {
#ifdef _WIN32
        emit consoleData("WinUSB driver not found. Installing...");
        QProcess zadic;
        QStringList zadicArgs;
        zadicArgs.append("--vid");
        zadicArgs.append(QString("0x%1").arg(Config::dfuVID, 4, 16, QChar('0')));
        zadicArgs.append("--pid");
        zadicArgs.append(QString("0x%1").arg(Config::dfuPID, 4, 16, QChar('0')));
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
#endif
    }
    emit consoleData("Flashing...");
    QProcess dfuUtil;
    QStringList dfuUtilArgs;
    dfuUtilArgs.append("-d");
    dfuUtilArgs.append(QString("%1").arg(Config::dfuVID, 4, 16, QChar('0')) + QString(":%1").arg(Config::dfuPID, 4, 16, QChar('0')));
    dfuUtilArgs.append("-a");
    dfuUtilArgs.append(QString("%1").arg(Config::dfuAlternate));
    dfuUtilArgs.append("-D");
    dfuUtilArgs.append(this->firmwarePath);
    dfuUtilArgs.append("-s");
    dfuUtilArgs.append(QString("0x%1").arg(Config::dfuseAddress, 8, 16, QChar('0')) + (this->massErase ? ":mass-erase:force" : ""));
    connect(&dfuUtil, &QProcess::readyReadStandardOutput, [this, &dfuUtil] {
        emit this->consoleData(dfuUtil.readAllStandardOutput());
    });
    connect(&dfuUtil, &QProcess::readyReadStandardError, [this, &dfuUtil] {
        emit this->consoleErrorData(dfuUtil.readAllStandardError());
    });
#ifdef _WIN32
    dfuUtil.start("dfu-util.exe", dfuUtilArgs);
#else
    dfuUtil.start(QCoreApplication::applicationDirPath() + "/dfu-util", dfuUtilArgs);
#endif
    if (!dfuUtil.waitForFinished(60 * 5 * 1000)) {
        emit consoleErrorData(QString("Launching dfu-util failed! Reason: %1").arg(dfuUtil.errorString()));
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
