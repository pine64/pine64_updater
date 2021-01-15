#include "connectpinecildialog.h"
#include "ui_connectpinecildialog.h"
#include "mainwindow.h"

ConnectPinecilDialog::ConnectPinecilDialog(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::ConnectPinecilDialog)
{
    ui->setupUi(this);
    setWindowFlags(windowFlags() & ~Qt::WindowContextHelpButtonHint);

}

ConnectPinecilDialog::~ConnectPinecilDialog()
{
    delete ui;
}

void ConnectPinecilDialog::on_buttonBox_rejected()
{

}

void ConnectPinecilDialog::on_ConnectPinecilDialog_rejected()
{

}
