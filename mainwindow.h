#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QTimer>
extern "C" {
#include <libusb-1.0/libusb.h>
}
#include <QtNetwork/QNetworkAccessManager>
#include <connectpinecildialog.h>
#include <atomic>

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE

enum class PinecilConnectionStatusEnum
{
    Disconnected,
    Connected,
    ConnectedNoDriver, // Only on Windows
    Error
};

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();
    std::atomic<PinecilConnectionStatusEnum> pinecilConnectionStatus;

public slots:
    void updatePinecilStatus();

private slots:
    void on_actionExit_triggered();

    void on_firmwareComboBox_currentIndexChanged(int index);

    void on_firmwareBrowseButton_clicked();

    void on_flashButton_clicked();

    void on_actionAbout_triggered();

private:
    Ui::MainWindow *ui;
    void initLibUsb();
    libusb_context* usbContext;
    int previousDevicesCount = -1;
    QTimer* pinecilCheckTimer;
    QNetworkAccessManager *networkMgr;
    QUrl binariesDownloadUrl;
    bool flashingPending = false;
    ConnectPinecilDialog* flashPendingDialog = nullptr;

    void ConsolePrint(const QString& text);
    void ConsolePrintError(const QString& text);
    void ConsolePrintWarning(const QString& text);
    void ConsolePrintInfo(const QString& text);
    void ConsolePrintSuccess(const QString& text);

    void Flash();
};
#endif // MAINWINDOW_H
