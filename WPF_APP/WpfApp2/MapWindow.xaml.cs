using ConsoleApp1;
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
using System.Windows.Shapes;

namespace WpfApp2
{
    /// <summary>
    /// Interaction logic for Window2.xaml
    /// </summary>
    public partial class MapWindow : Window
    {
        BitmapImage bitmapImage = new BitmapImage(new Uri("pack://application:,,,/WpfApp2;component/678111-map-marker-512.png"));
        const int CoordMin = 0, CoordMax = 500, XOffset = 150, YOffset = 50;

        public MapWindow()
        {
            InitializeComponent();
            var height = Height;
            var width = Width;
            var background = new SolidColorBrush(Colors.White);
            foreach (var country in DAL.GetRowsOfType<DangerousPlace>("call dangerous_places(@1)", ("@1", 16)))
            {
                var margin = new Thickness(
                    (country.X - CoordMin) / (CoordMax - CoordMin) * width
                    * (width - 2 * XOffset) / width + XOffset,
                    (country.Y - CoordMin) / (CoordMax - CoordMin) * height
                    * (height - 2 * YOffset) / height + YOffset,
                    0, 0);
                grid.Children.Add(new Image
                {
                    Source = bitmapImage,
                    HorizontalAlignment = HorizontalAlignment.Left,
                    VerticalAlignment = VerticalAlignment.Top,
                    Margin = margin,
                    Height = 35,
                    Width = 35,
                });
                grid.Children.Add(new Label
                {
                    Content = country.Name,
                    HorizontalAlignment = HorizontalAlignment.Left,
                    VerticalAlignment = VerticalAlignment.Top,
                    Margin = margin,
                    Background = background,
                });
            }
        }
    }
}
