using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Data;
using System.Windows.Controls;

namespace ConsoleApp1
{
    public static class DAL
    {
        public static string userId;
        static MySqlConnection connection;

        public static void Start(string server, string userId, string password, string database)
        {
            DAL.userId = userId;
            connection = new MySqlConnection($"server={server};user id={userId};database={database};password={password}");
            connection.Open();
        }

        public static void Stop() => connection.Dispose();

        public static void UpdateMilitaryConflict(MilitaryConflict conflict)
        {
            var command = new MySqlCommand("update military_conflicts set military_conflicts_used_weapon = @usedWeapon where military_conflicts_id = @id", connection);
            command.Parameters.AddWithValue("@usedWeapon", conflict.UsedWeapon);
            command.Parameters.AddWithValue("@id", conflict.Id);
            Console.WriteLine($"(Executing command \"{command.CommandText}\")");
            Console.WriteLine($"Number of rows affected: {command.ExecuteNonQuery()}");
            Console.WriteLine();
        }

        public static List<T> GetRowsOfType<T>(string cmdText, params (string,object)[] ps) where T : Row, new()
        {
            var command = ParametriseCommand(cmdText, ps);
            var rows = new List<T>();
            Console.WriteLine($"(Executing command \"{command.CommandText}\")");
            using (var dataReader = command.ExecuteReader())
            {
                while (dataReader.Read())
                {
                    var t = new T();
                    t.ReadFrom(dataReader);
                    rows.Add(t);
                }
            }
            return rows;
        }

        public static void PrintTableFrom(string cmdText, bool printTypes = false)
        {
            var command = new MySqlCommand(cmdText, connection);
            string[] names = default;
            int[] lengths = default;
            var values = new List<string[]>();
            Console.WriteLine($"(Executing command \"{command.CommandText}\")");
            using (var dataReader = command.ExecuteReader())
            { 
                names = new string[dataReader.FieldCount];
                lengths = new int[dataReader.FieldCount];
                for (int i = 0; i < dataReader.FieldCount; i++)
                {
                    names[i] = dataReader.GetName(i);
                    if (printTypes)
                    {
                        names[i] += $" {dataReader.GetFieldType(dataReader.GetName(i))}";
                    }
                    if (names[i].Length > lengths[i])
                    {
                        lengths[i] = names[i].Length;
                    }
                }
                while (dataReader.Read())
                {
                    var vs = new string[dataReader.FieldCount];
                    for (int i = 0; i < dataReader.FieldCount; i++)
                    {
                        vs[i] = dataReader.GetString(i);
                        if (vs[i].Length > lengths[i])
                        {
                            lengths[i] = vs[i].Length;
                        }
                    }
                    values.Add(vs);
                }
            }
            DrawHorizontalLine(lengths);
            DrawRow(names, lengths);
            for (int i = 0; i < values.Count; i++)
            {
                DrawHorizontalLine(lengths);
                DrawRow(values[i], lengths);
            }
            DrawHorizontalLine(lengths);
        }

        private static void DrawRow(string[] names, int[] lengths)
        {
            for (int j = 0; j < names.Length; j++)
            {
                Console.Write("|" + names[j].PadRight(lengths[j]));
            }
            Console.WriteLine("|");
        }

        private static void DrawHorizontalLine(int[] lengths)
        {
            for (int j = 0; j < lengths.Length; j++)
            {
                Console.Write("+" + new string('-', lengths[j]));
            }
            Console.WriteLine("+");
        }

        public static void PrintToDataGrid(string cmdText, DataGrid dataGrid, params (string, object)[] ps)
        {
            var command = ParametriseCommand(cmdText, ps);
            var table = new DataTable();
            Console.WriteLine($"(Executing command \"{command.CommandText}\")");
            using (var dataReader = command.ExecuteReader())
            {
                var values = new object[dataReader.FieldCount];
                for (int i = 0; i < dataReader.FieldCount; i++)
                {
                    table.Columns.Add(dataReader.GetName(i), dataReader.GetFieldType(i));
                }
                while (dataReader.Read())
                {
                    dataReader.GetValues(values);
                    table.Rows.Add(values);
                }
            }
            dataGrid.ItemsSource = table.DefaultView;
        }

        public static int ExecuteNonQuery(string cmdText, params (string, object)[] ps)
            => ParametriseCommand(cmdText, ps).ExecuteNonQuery();

        static MySqlCommand ParametriseCommand(string cmdText, (string, object)[] ps)
        {
            var command = new MySqlCommand(cmdText, connection);
            foreach (var p in ps)
            {
                command.Parameters.AddWithValue(p.Item1, p.Item2);
            }
            return command;
        }
    }
}
