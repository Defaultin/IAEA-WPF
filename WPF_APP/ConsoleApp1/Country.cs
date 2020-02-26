using MySql.Data.MySqlClient;
using System.Data.SqlTypes;

namespace ConsoleApp1
{
    public class Country : Row
    {
        public string Code { get; set; }
        public string Name { get; set; }
        public string Continent { get; set; }
        public string Region { get; set; }
        public float SurfaceArea { get; set; }
        public int Population { get; set; }
        public float? LifeExpectancy { get; set; }
        public float GNP { get; set; }
        public string LocalName { get; set; }
        public string GovernmentForm { get; set; }
        public string HeadOfState { get; set; }
        public float Budget { get; set; }
        public float X { get; set; }
        public float Y { get; set; }

        public override void ReadFrom(MySqlDataReader dataReader)
        {
            Code = dataReader.GetString(0);
            Name = dataReader.GetString(1);
            Continent = dataReader.GetString(2);
            Region = dataReader.GetString(3);
            SurfaceArea = dataReader.GetFloat(4);
            Population = dataReader.GetInt32(5);
            try
            {
                LifeExpectancy = dataReader.GetFloat(6);
            }
            catch (SqlNullValueException)
            {
                LifeExpectancy = null;
            }
            GNP = dataReader.GetFloat(7);
            LocalName = dataReader.GetString(8);
            GovernmentForm = dataReader.GetString(9);
            HeadOfState = dataReader.GetString(10);
            Budget = dataReader.GetFloat(11);
            X = dataReader.GetFloat(12);
            Y = dataReader.GetFloat(13);
        }
    }
}
