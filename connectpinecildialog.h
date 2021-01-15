#ifndef CONNECTPINECILDIALOG_H
#define CONNECTPINECILDIALOG_H

#include <QDialog>

namespace Ui {
class ConnectPinecilDialog;
}

class ConnectPinecilDialog : public QDialog
{
    Q_OBJECT

public:
    explicit ConnectPinecilDialog(QWidget *parent = nullptr);
    ~ConnectPinecilDialog();

private slots:
    void on_buttonBox_rejected();

    void on_ConnectPinecilDialog_rejected();

private:
    Ui::ConnectPinecilDialog *ui;
};

#endif // CONNECTPINECILDIALOG_H
