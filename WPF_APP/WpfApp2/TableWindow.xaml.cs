using ConsoleApp1;
using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Data;
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
using System.Windows.Shapes;

namespace WpfApp2
{
    public partial class TableWindow : Window
    {
        MapWindow mapWindow;

        public TableWindow()
        {
            InitializeComponent();
            Title += " - " + DAL.userId;
        }

        int Execute(string cmdText, params (string, object)[] ps)
        {
            int result = 0;
            try
            {
                result = DAL.ExecuteNonQuery(cmdText, ps);
            }
            catch (MySqlException ex)
            {
                status.Text = ex.Message;
            }
            return result;
        }

        void Display(string cmdText, params (string, object)[] ps)
        {
            try
            {
                DAL.PrintToDataGrid(cmdText, dataGrid, ps);
            }
            catch (MySqlException ex)
            {
                status.Text = ex.Message;
            }
        }

        void Button_Click_ShowMap(object sender, RoutedEventArgs e)
        {
            mapWindow?.Close();
            try
            {
                mapWindow = new MapWindow();
                mapWindow.Show();
            }
            catch (MySqlException ex)
            {
                status.Text = ex.Message;
            }
        }

        void Button_Click_LogOut(object sender, RoutedEventArgs e)
        {
            DAL.Stop();
            mapWindow?.Close();
            new LoginWindow().Show();
            Close();
        }

        void Button_Click_Transaction1(object sender, RoutedEventArgs e) => Execute("call invest(@1, @2, @3)",
            ("@1", t1TextBox1.Text), ("@2", t1TextBox2.Text), ("@3", t1TextBox3.Text));

        void Button_Click_Transaction2(object sender, RoutedEventArgs e) => Execute("call tax(@1, @2, @3)",
            ("@1", t2TextBox1.Text), ("@2", t2TextBox2.Text), ("@3", t2TextBox3.Text));

        void Button_Click_Transaction3(object sender, RoutedEventArgs e) => Execute("call weapons_purchase(@1, @2, @3)",
            ("@1", t3TextBox1.Text), ("@2", t3TextBox2.Text), ("@3", t3TextBox3.Text));

        void Button_Click_View1(object sender, RoutedEventArgs e) => Display("select * from plants_info");

        void Button_Click_View2(object sender, RoutedEventArgs e) => Display("select * from factory_info");

        void Button_Click_View3(object sender, RoutedEventArgs e) => Display("select * from country_info");

        void Button_Click_View4(object sender, RoutedEventArgs e) => Display("select * from activities_info");

        void Button_Click_View5(object sender, RoutedEventArgs e) => Display("select * from conflicts_info");

        void Button_Click_View6(object sender, RoutedEventArgs e) => Display("select * from financial_info");

        void Button_Click_View7(object sender, RoutedEventArgs e) => Display("select * from investments_info");
        
        void Button_Click_View8(object sender, RoutedEventArgs e) => Display("select * from tax_info");

        void Button_Click_Procedure1(object sender, RoutedEventArgs e)
        {
            Execute("call audit_the_enterprise()");
            Display("select * from enterprise_audit_results");
        }

        void Button_Click_Procedure2(object sender, RoutedEventArgs e)
        {
            Execute("call radioactive_waste()");
            Display("select * from nuclear_waste");
        }

        void Button_Click_Procedure3(object sender, RoutedEventArgs e) => Display("call dangerous_places(@1)", ("@1", 16));

        void Window_Closed(object sender, EventArgs e) => mapWindow?.Close();
    }
}
