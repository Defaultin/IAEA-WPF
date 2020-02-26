using MySql.Data.MySqlClient;
using System;

namespace ConsoleApp1
{
    public class MilitaryConflict : Row
    {
        public int Id { get; set; }
        public string ConflictingParty1 { get; set; }
        public string ConflictingParty2 { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string ConflictCause { get; set; }
        public int UsedWeapon { get; set; }

        public override void ReadFrom(MySqlDataReader dataReader)
        {
            Id = dataReader.GetInt32(0);
            ConflictingParty1 = dataReader.GetString(1);
            ConflictingParty2 = dataReader.GetString(2);
            StartDate = dataReader.GetDateTime(3);
            EndDate = dataReader.GetDateTime(4);
            ConflictCause = dataReader.GetString(5);
            UsedWeapon = dataReader.GetInt32(6);
        }
    }
}
