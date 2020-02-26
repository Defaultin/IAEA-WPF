using MySql.Data.MySqlClient;

namespace ConsoleApp1
{
    public abstract class Row
    {
        public abstract void ReadFrom(MySqlDataReader dataReader);
    }
}
