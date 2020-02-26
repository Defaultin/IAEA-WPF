using ConsoleApp1;
using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace WpfApp2
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class LoginWindow : Window
    {
        public LoginWindow()
        {
            InitializeComponent();
        }

        private void Button_Click_Connect(object sender, RoutedEventArgs e)
        {
            try
            {
                DAL.Start("localhost", userId.Text, password.Text, "iaea");
                new TableWindow().Show();
                Close();
            }
            catch (MySqlException ex)
            {
                status.Text = ex.Message;
            }
        }
    }
}
