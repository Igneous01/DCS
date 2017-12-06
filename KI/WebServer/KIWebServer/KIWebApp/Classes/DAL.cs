﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using KIWebApp.Models;
using MySql.Data;
using MySql.Data.MySqlClient;
using System.Data;

namespace KIWebApp.Classes
{
    public class DAL : IDAL
    {
        private const string SP_GET_SERVERS = "websp_GetServersList";
        private const string SP_GET_ONLINEPLAYERS = "websp_GetOnlinePlayers";
        private const string SP_GET_GAMEMAP = "websp_GetGameMap";
        private const string SP_GET_LAYERS = "websp_GetGameMapLayers";
        private const string SP_GET_AIRPORTS = "websp_GetAirports";
        private const string SP_GET_DEPOTS= "websp_GetDepots";
        private const string SP_GET_CAPTUREPOINTS = "websp_GetCapturePoints";
        private const string SP_GET_GAME = "websp_GetGame";
        private string _DBConnection;
       
        public DAL()
        {
            _DBConnection = System.Configuration.ConfigurationManager.ConnectionStrings["DBMySqlConnect"].ConnectionString;
        }

        List<AirportModel> IDAL.GetAirports(int serverID)
        {
            MySqlConnection conn = new MySqlConnection(_DBConnection);
            try
            {
                conn.Open();
                return ((IDAL)this).GetAirports(serverID, ref conn);
            }
            finally
            {
                conn.Close();
            }
        }

        List<AirportModel> IDAL.GetAirports(int serverID, ref MySqlConnection conn)
        {
            if (conn.State == ConnectionState.Closed || conn.State == ConnectionState.Broken)
                conn.Open();
            List<AirportModel> airports = new List<AirportModel>();
            MySqlCommand cmd = new MySql.Data.MySqlClient.MySqlCommand(SP_GET_AIRPORTS);
            cmd.Connection = conn;
            cmd.CommandType = System.Data.CommandType.StoredProcedure;
            cmd.Parameters.Add(new MySqlParameter("ServerID", serverID));
            MySqlDataReader rdr = cmd.ExecuteReader();
            DataTable dt = new DataTable();
            dt.Load(rdr);

            foreach (DataRow dr in dt.Rows)
            {
                AirportModel port = new AirportModel
                {
                    ID = dr.Field<int>("AirportID"),
                    Name = dr.Field<string>("Name"),
                    LatLong = dr.Field<string>("LatLong"),
                    MGRS = dr.Field<string>("MGRS"),           
                    Status = dr.Field<string>("Status"),
                    Type = dr.Field<string>("Type"),
                    Pos = new Position(dr.Field<double>("X"), dr.Field<double>("Y")),
                    Image = dr.Field<string>("ImagePath")
                };
                airports.Add(port);
            }
            return airports;
        }

        List<CapturePointModel> IDAL.GetCapturePoints(int serverID)
        {
            MySqlConnection conn = new MySqlConnection(_DBConnection);
            try
            {
                conn.Open();
                return ((IDAL)this).GetCapturePoints(serverID, ref conn);
            }
            finally
            {
                conn.Close();
            }
        }

        List<CapturePointModel> IDAL.GetCapturePoints(int serverID, ref MySqlConnection conn)
        {
            if (conn.State == ConnectionState.Closed || conn.State == ConnectionState.Broken)
                conn.Open();
            List<CapturePointModel> capturepoints = new List<CapturePointModel>();
            MySqlCommand cmd = new MySql.Data.MySqlClient.MySqlCommand(SP_GET_CAPTUREPOINTS);
            cmd.Connection = conn;
            cmd.CommandType = System.Data.CommandType.StoredProcedure;
            cmd.Parameters.Add(new MySqlParameter("ServerID", serverID));
            MySqlDataReader rdr = cmd.ExecuteReader();
            DataTable dt = new DataTable();
            dt.Load(rdr);

            foreach (DataRow dr in dt.Rows)
            {
                CapturePointModel capturepoint = new CapturePointModel
                {
                    ID = dr.Field<int>("CapturePointID"),
                    Name = dr.Field<string>("Name"),
                    LatLong = dr.Field<string>("LatLong"),
                    MGRS = dr.Field<string>("MGRS"),
                    Capacity = dr.Field<int>("CurrentCapacity") + " / " + dr.Field<int>("Capacity"),
                    Status = dr.Field<string>("Status"),
                    BlueUnits = dr.Field<int>("BlueUnits"),
                    RedUnits = dr.Field<int>("RedUnits"),
                    Pos = new Position(dr.Field<double>("X"), dr.Field<double>("Y")),
                    Image = dr.Field<string>("ImagePath")
                };
                capturepoints.Add(capturepoint);
            }
            return capturepoints;
        }

        List<DepotModel> IDAL.GetDepots(int serverID)
        {
            MySqlConnection conn = new MySqlConnection(_DBConnection);
            try
            {
                conn.Open();
                return ((IDAL)this).GetDepots(serverID, ref conn);
            }
            finally
            {
                conn.Close();
            }
        }

        List<DepotModel> IDAL.GetDepots(int serverID, ref MySqlConnection conn)
        {
            if (conn.State == ConnectionState.Closed || conn.State == ConnectionState.Broken)
                conn.Open();
            List<DepotModel> depots = new List<DepotModel>();
            MySqlCommand cmd = new MySql.Data.MySqlClient.MySqlCommand(SP_GET_DEPOTS)
            {
                Connection = conn,
                CommandType = System.Data.CommandType.StoredProcedure
            };
            cmd.Parameters.Add(new MySqlParameter("ServerID", serverID));
            MySqlDataReader rdr = cmd.ExecuteReader();
            DataTable dt = new DataTable();
            dt.Load(rdr);

            foreach (DataRow dr in dt.Rows)
            {
                DepotModel depot = new DepotModel
                {
                    ID = dr.Field<int>("DepotID"),
                    Name = dr.Field<string>("Name"),
                    LatLong = dr.Field<string>("LatLong"),
                    MGRS = dr.Field<string>("MGRS"),
                    Capacity = dr.Field<int>("CurrentCapacity") + " / " + dr.Field<int>("Capacity"),
                    Status = dr.Field<string>("Status"),
                    Resources = dr.Field<string>("Resources"),
                    Pos = new Position(dr.Field<double>("X"), dr.Field<double>("Y")),
                    Image = dr.Field<string>("ImagePath")
                };
                depots.Add(depot);
            }
            return depots;
        }

        GameModel IDAL.GetGame(int serverID)
        {
            MySqlConnection conn = new MySqlConnection(_DBConnection);
            try
            {
                conn.Open();
                return ((IDAL)this).GetGame(serverID, ref conn);
            }
            finally
            {
                conn.Close();
            }
        }

        GameModel IDAL.GetGame(int serverID, ref MySqlConnection conn)
        {
            if (conn.State == ConnectionState.Closed || conn.State == ConnectionState.Broken)
                conn.Open();

            GameModel g = new GameModel();
            MySqlCommand cmd = new MySql.Data.MySqlClient.MySqlCommand(SP_GET_GAME)
            {
                Connection = conn,
                CommandType = System.Data.CommandType.StoredProcedure
            };
            cmd.Parameters.Add(new MySqlParameter("ServerID", serverID));
            MySqlDataReader rdr = cmd.ExecuteReader();
            DataTable dt = new DataTable();
            dt.Load(rdr);

            foreach (DataRow dr in dt.Rows)
            {
                TimeSpan rt;
                if (dr["RestartTime"] == DBNull.Value || dr["RestartTime"] == null)
                {
                    rt = new TimeSpan(0, 0, 0);
                }
                else
                {
                    rt = new TimeSpan(TimeSpan.TicksPerSecond * dr.Field<int>("RestartTime"));
                }

                string status = "Offline";
                if (dr["Status"] != DBNull.Value && dr["Status"] != null)
                    status = dr.Field<string>("Status");

                g.ServerID = serverID;
                g.ServerName = dr.Field<string>("ServerName");
                g.IPAddress = dr.Field<string>("IPAddress");
                g.OnlinePlayersCount = Convert.ToInt32(dr.Field<long>("OnlinePlayerCount"));
                g.RestartTime = rt.ToString();
                g.Status = status;
                g.Depots = ((IDAL)this).GetDepots(serverID, ref conn);
                g.CapturePoints = ((IDAL)this).GetCapturePoints(serverID, ref conn);
                g.OnlinePlayers = ((IDAL)this).GetOnlinePlayers(serverID, ref conn);
                g.Airports = ((IDAL)this).GetAirports(serverID, ref conn);
                g.Map = ((IDAL)this).GetGameMap(serverID, ref conn);
                break;
            }
            return g;
        }

        GameMapModel IDAL.GetGameMap(int serverID)
        {
            MySqlConnection conn = new MySqlConnection(_DBConnection);
            try
            {
                conn.Open();
                return ((IDAL)this).GetGameMap(serverID, ref conn);
            }
            finally
            {
                conn.Close();
            }
        }

        GameMapModel IDAL.GetGameMap(int serverID, ref MySqlConnection conn)
        {
            if (conn.State == ConnectionState.Closed || conn.State == ConnectionState.Broken)
                conn.Open();

            GameMapModel map = new GameMapModel();
            MySqlCommand cmd = new MySql.Data.MySqlClient.MySqlCommand(SP_GET_GAMEMAP)
            {
                Connection = conn,
                CommandType = System.Data.CommandType.StoredProcedure
            };
            cmd.Parameters.Add(new MySqlParameter("ServerID", serverID));
            MySqlDataReader rdr = cmd.ExecuteReader();
            DataTable dt = new DataTable();
            dt.Load(rdr);

            foreach (DataRow dr in dt.Rows)
            {
                map.ImagePath = dr.Field<string>("ImagePath");
                map.DCSOriginPosition = new Position(dr.Field<double>("X"), dr.Field<double>("Y"));
                map.Resolution = new Resolution(dr.Field<double>("Width"), dr.Field<double>("Height"));
                map.Ratio = dr.Field<double>("Ratio");
                map.Layers = ((IDAL)this).GetMapLayers(dr.Field<int>("GameMapID"), ref conn);
                break;
            }
            return map;
        }

        List<MapLayerModel> IDAL.GetMapLayers(int mapID)
        {
            MySqlConnection conn = new MySqlConnection(_DBConnection);
            try
            {
                conn.Open();
                return ((IDAL)this).GetMapLayers(mapID, ref conn);
            }
            finally
            {
                conn.Close();
            }
        }

        List<MapLayerModel> IDAL.GetMapLayers(int mapID, ref MySqlConnection conn)
        {
            if (conn.State == ConnectionState.Closed || conn.State == ConnectionState.Broken)
                conn.Open();
            List<MapLayerModel> layers = new List<MapLayerModel>();
            MySqlCommand cmd = new MySql.Data.MySqlClient.MySqlCommand(SP_GET_LAYERS)
            {
                Connection = conn,
                CommandType = System.Data.CommandType.StoredProcedure
            };
            cmd.Parameters.Add(new MySqlParameter("GameMapID", mapID));
            MySqlDataReader rdr = cmd.ExecuteReader();
            DataTable dt = new DataTable();
            dt.Load(rdr);

            foreach (DataRow dr in dt.Rows)
            {
                MapLayerModel layer = new MapLayerModel(new Resolution(dr.Field<double>("Width"), dr.Field<double>("Height")), dr.Field<string>("ImagePath"));
                layers.Add(layer);
            }
            return layers;
        }

        MarkerViewModel IDAL.GetMarkers(int serverID)
        {
            MySqlConnection conn = new MySqlConnection(_DBConnection);
            try
            {
                conn.Open();
                return ((IDAL)this).GetMarkers(serverID, ref conn);
            }
            finally
            {
                conn.Close();
            }
        }

        MarkerViewModel IDAL.GetMarkers(int serverID, ref MySqlConnection conn)
        {
            MarkerViewModel mm = new MarkerViewModel()
            {
                Depots = ((IDAL)this).GetDepots(serverID, ref conn),
                CapturePoints = ((IDAL)this).GetCapturePoints(serverID, ref conn),
                Airports = ((IDAL)this).GetAirports(serverID, ref conn)
            };

            return mm;
        }

        List<OnlinePlayerModel> IDAL.GetOnlinePlayers(int serverID)
        {
            MySqlConnection conn = new MySqlConnection(_DBConnection);
            try
            {
                conn.Open();
                return ((IDAL)this).GetOnlinePlayers(serverID, ref conn);
            }
            finally
            {
                conn.Close();
            }
        }

        List<OnlinePlayerModel> IDAL.GetOnlinePlayers(int serverID, ref MySqlConnection conn)
        {
            if (conn.State == ConnectionState.Closed || conn.State == ConnectionState.Broken)
                conn.Open();

            List<OnlinePlayerModel> players = new List<OnlinePlayerModel>();
            MySqlCommand cmd = new MySql.Data.MySqlClient.MySqlCommand(SP_GET_ONLINEPLAYERS)
            {
                Connection = conn,
                CommandType = System.Data.CommandType.StoredProcedure
            };
            cmd.Parameters.Add(new MySqlParameter("ServerID", serverID));
            MySqlDataReader rdr = cmd.ExecuteReader();
            DataTable dt = new DataTable();
            dt.Load(rdr);

            foreach (DataRow dr in dt.Rows)
            {
                OnlinePlayerModel player = new OnlinePlayerModel
                {
                    UCID = dr.Field<string>("UCID"),
                    Name = dr.Field<string>("Name"),
                    Role = dr.Field<string>("Role"),
                    RoleImage = dr.Field<string>("RoleImage"),
                    Side = dr.Field<int>("Side") == 1 ? "Red" : "Blue",
                    Ping = dr.Field<string>("Ping")
                };
                players.Add(player);
            }
            return players;
        }

        List<ServerModel> IDAL.GetServers()
        {
            MySqlConnection conn = new MySqlConnection(_DBConnection);
            try
            {
                conn.Open();
                return ((IDAL)this).GetServers(ref conn);
            }
            finally
            {
                conn.Close();
            }              
        }

        List<ServerModel> IDAL.GetServers(ref MySqlConnection conn)
        {
            if (conn.State == ConnectionState.Closed || conn.State == ConnectionState.Broken)
                conn.Open();
            List<ServerModel> servers = new List<ServerModel>();
            MySqlCommand cmd = new MySql.Data.MySqlClient.MySqlCommand(SP_GET_SERVERS)
            {
                Connection = conn,
                CommandType = System.Data.CommandType.StoredProcedure
            };
            MySqlDataReader rdr = cmd.ExecuteReader();
            DataTable dt = new DataTable();
            dt.Load(rdr);

            foreach (DataRow dr in dt.Rows)
            {
                TimeSpan rt;
                if (dr["RestartTime"] == DBNull.Value || dr["RestartTime"] == null)
                {
                    rt = new TimeSpan(0, 0, 0);
                }
                else
                {
                    rt = new TimeSpan(TimeSpan.TicksPerSecond * dr.Field<int>("RestartTime"));
                }

                string status = "Offline";
                string img = "Images/status-red-128x128.png";
                if (dr["Status"] != DBNull.Value && dr["Status"] != null)
                {
                    status = dr.Field<string>("Status");
                    if (status.ToUpper() == "ONLINE")
                        img = "Images/status-green-128x128.png";
                    else if (status.ToUpper() == "OFFLINE")
                        img = "Images/status-red-128x128.png";
                    else
                        img = "Images/status-yellow-128x128.png";
                }

                ServerModel server = new ServerModel
                {
                    ServerID = dr.Field<int>("ServerID"),
                    ServerName = dr.Field<string>("ServerName"),
                    IPAddress = dr.Field<string>("IPAddress"),
                    Status = status,
                    StatusImage = img,
                    RestartTime = rt,
                    OnlinePlayers = Convert.ToInt32(dr.Field<long>("OnlinePlayers"))
                };
                servers.Add(server);
            }

            return servers;
        }



    }
}