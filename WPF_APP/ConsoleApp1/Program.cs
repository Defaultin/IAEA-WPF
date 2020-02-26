using MySql.Data.MySqlClient;
using System;
using System.Linq;

namespace ConsoleApp1
{
    class Program
    {
        static void Main()
        {
            while (true)
            {
                Console.Write("server  : ");
                var server = ReadOrDefault("localhost");
                Console.Write("user id : ");
                var userId = ReadOrDefault("root");
                Console.Write("password: ");
                var password = ReadOrDefault("root");
                Console.Write("database: ");
                var database = ReadOrDefault("iaea");
                try
                {
                    DAL.Start(server, userId, password, database);
                    break;
                }
                catch (MySqlException e)
                {
                    Console.WriteLine(e.Message);
                }
                finally
                {
                    Console.WriteLine();
                }
            }
            DAL.PrintTableFrom("select * from plants_info");

            const string CmdText = "select * from largest_production_centers limit 5";
            DAL.PrintTableFrom(CmdText);

            const int Year = 2000;
            Console.WriteLine();
            Console.WriteLine($"Production centers established before {Year}:");
            Console.WriteLine(string.Join(", ", DAL.GetRowsOfType<ProductionCenter>(CmdText)
                .Where(p => p.EstablishmentDate.Year < Year).Select(p => p.Name)));
            Console.WriteLine();

            DAL.PrintTableFrom("select * from military_conflicts limit 5");

            Console.WriteLine();
            Console.Write("Enter conflict id: ");
            var conflict = DAL.GetRowsOfType<MilitaryConflict>(
                "select * from military_conflicts where military_conflicts_id=@id", ("@id", Console.ReadLine())
                ).Single();
            Console.Write("Enter new value for used_weapon: ");
            conflict.UsedWeapon = int.Parse(Console.ReadLine());
            DAL.UpdateMilitaryConflict(conflict);

            DAL.PrintTableFrom("select * from military_conflicts limit 5");

            DAL.Stop();
        }

        static string ReadOrDefault(string defaultValue)
        {
            string input = Console.ReadLine();
            if (string.IsNullOrEmpty(input))
            {
                Console.WriteLine(defaultValue);
                return defaultValue;
            }
            return input;
        }
    }
}
