using MySql.Data.MySqlClient;
using System;

namespace ConsoleApp1
{
    public class ProductionCenter : Row
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string CountryCode { get; set; }
        public float Budget { get; set; }
        public DateTime EstablishmentDate { get; set; }
        public string Founder { get; set; }

        public override void ReadFrom(MySqlDataReader dataReader)
        {
            Id = dataReader.GetInt32(0);
            Name = dataReader.GetString(1);
            CountryCode = dataReader.GetString(2);
            Budget = dataReader.GetFloat(3);
            EstablishmentDate = dataReader.GetDateTime(4);
            Founder = dataReader.GetString(5);
        }
    }
}
