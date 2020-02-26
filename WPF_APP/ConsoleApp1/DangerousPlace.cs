using MySql.Data.MySqlClient;

namespace ConsoleApp1
{
    public class DangerousPlace : Row
    {
        public string Name { get; set; }
        public float X { get; set; }
        public float Y { get; set; }

        public override void ReadFrom(MySqlDataReader dataReader)
        {
            Name = dataReader.GetString(0);
            X = dataReader.GetFloat(1);
            Y = dataReader.GetFloat(2);
        }
    }
}
