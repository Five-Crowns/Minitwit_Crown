using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SQLite;
using System.Linq;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using Scriban;

namespace MiniTwit
{
    public class MiniTwitController : Controller
    {
        private readonly string _connectionString = "Data Source=minitwit.db";

        public IActionResult Timeline()
        {
            var userId = HttpContext.Session.GetInt32("UserId");
            if (userId == null)
                return RedirectToAction("PublicTimeline");

            var messages = new List<Dictionary<string, object>>();
            using (var connection = new SQLiteConnection(_connectionString))
            {
                connection.Open();
                using (var command = new SQLiteCommand("SELECT * FROM message WHERE flagged = 0 ORDER BY pub_date DESC LIMIT 30", connection))
                using (var reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        var message = new Dictionary<string, object>();
                        for (int i = 0; i < reader.FieldCount; i++)
                        {
                            message[reader.GetName(i)] = reader.GetValue(i);
                        }
                        messages.Add(message);
                    }
                }
            }
            return View(messages);
        }

        public IActionResult PublicTimeline()
        {
            var messages = new List<Dictionary<string, object>>();
            using (var connection = new SQLiteConnection(_connectionString))
            {
                connection.Open();
                using (var command = new SQLiteCommand("SELECT * FROM message WHERE flagged = 0 ORDER BY pub_date DESC LIMIT 30", connection))
                using (var reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        var message = new Dictionary<string, object>();
                        for (int i = 0; i < reader.FieldCount; i++)
                        {
                            message[reader.GetName(i)] = reader.GetValue(i);
                        }
                        messages.Add(message);
                    }
                }
            }
            return View(messages);
        }

        public IActionResult Login() => View();

        [HttpPost]
        public IActionResult Login(string username, string password)
        {
            using (var connection = new SQLiteConnection(_connectionString))
            {
                connection.Open();
                using (var command = new SQLiteCommand("SELECT user_id, pw_hash FROM user WHERE username = @username", connection))
                {
                    command.Parameters.AddWithValue("@username", username);
                    using (var reader = command.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            int userId = reader.GetInt32(0);
                            string passwordHash = reader.GetString(1);
                            if (BCrypt.Net.BCrypt.Verify(password, passwordHash))
                            {
                                HttpContext.Session.SetInt32("UserId", userId);
                                return RedirectToAction("Timeline");
                            }
                        }
                    }
                }
            }
            ViewBag.Error = "Invalid username or password";
            return View();
        }
    }
}
