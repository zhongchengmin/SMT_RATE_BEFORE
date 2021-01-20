using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data;
using Oracle.DataAccess.Client;
using System.Web.Configuration;
using System.Text;

namespace SMT_RATE_BEFORE.DBConnection
{
    public class DBConnection
    {
        private OracleConnection Connection;
        public  DBConnection(string tns)
        {
            string ds = "";
            switch (tns)
            {
                case "FMMESPD":
                    ds = "data source =(DESCRIPTION=  (ADDRESS= (PROTOCOL=TCP) (HOST=10.178.1.68) (PORT=1521) ) (CONNECT_DATA= (SERVER=dedicated) (SERVICE_NAME=PHACR)  ) );user id= FMMESPD;password=FMMESPD123;Pooling=false ";
                    break;
                case "FMMESRPT":///裁切印刷廠
                    ds = "data source =(DESCRIPTION=  (ADDRESS= (PROTOCOL=TCP) (HOST=10.178.1.68) (PORT=1521) ) (CONNECT_DATA= (SERVER=dedicated) (SERVICE_NAME=PHACR)  ) );user id= FMMESRPT;password=FMMESRPT123;Pooling=false ";
                    break;
                default :
                    break;
            }
            SetConn(ds);
        }       
     
        /// <summary>
        /// OracleConnection設定
        /// </summary>
        /// <param name="conn">鏈接字符串</param>
        public void SetConn(string conn)
        {

            Connection = new OracleConnection(conn);

        }

        /// <summary>
        /// 打開oralce鏈接
        /// </summary>
        private void OpenConn()
        {
            if (Connection.State != ConnectionState.Open)
                Connection.Open();
        }
        /// <summary>
        /// 關閉鏈接
        /// </summary>
        private void CloseConn()
        {
            if (Connection.State != ConnectionState.Closed)
                Connection.Close();
        }
        /// <summary>
        /// 返回select 語句結果集合
        /// </summary>
        /// <param name="sql">select語句數組</param>
        /// <returns></returns>
        public DataSet ExcuteManyQuery(string[] sql)
        {

            DataSet dataset = new DataSet();
            OpenConn();
            try
            {
                for (int i = 0; i < sql.Length; i++)
                {
                    OracleDataAdapter OraDA = new OracleDataAdapter(sql[i], Connection);

                    DataTable datatable = new DataTable();
                    OraDA.Fill(datatable);
                    dataset.Tables.Add(datatable);

                }
                return dataset;
            }
            catch (Exception ex)
            { throw new Exception(ex.Message); }
            finally
            {

                dataset.Dispose();
                CloseConn();
            }

        }
        /// <summary>
        /// 返回單一select 語句結果集合
        /// </summary>
        /// <param name="sql">select語句</param>
        /// <returns></returns>
        public DataSet ExcuteSingleQuery(string sql)
        {
            DataSet dataSet = new DataSet();

            OpenConn();
            try
            {
                OracleDataAdapter OraDA = new OracleDataAdapter(sql, Connection);

                OraDA.Fill(dataSet);
                return dataSet;
            }
            catch (Exception ex)
            { throw new Exception(ex.Message); }
            finally
            {
                dataSet.Dispose();
                Connection.Dispose();
                CloseConn();
            }

        }

        public DataSet ExcuteSingleQuery1(string sql, OracleParameter[] parameter)
        {

            DataSet dataSet = new DataSet();
            Connection.Open();
            try
            {
                OracleDataAdapter OraDA = new OracleDataAdapter(sql, Connection);
                OraDA.SelectCommand.BindByName = true;
                if (parameter != null)
                {
                    foreach (var param in parameter)
                    {
                        OraDA.SelectCommand.Parameters.Add(param);
                    }
                }

                OraDA.Fill(dataSet);
                return dataSet;
            }
            catch (Exception ex)
            { 
                throw new Exception(ex.Message);
            }
            finally
            {
                dataSet.Dispose();
                Connection.Dispose();
            }

        }


        public int ExecuteNonQuery(string sql)
        {
            OpenConn();
            OracleCommand com = Connection.CreateCommand();
            com.CommandText = sql;
            int qty = com.ExecuteNonQuery();

            Connection.Dispose();
            CloseConn();
            return qty;
        }

        public void ExecuteNonQuery(StringBuilder sql)
        {
            string[] sqls = sql.ToString().Split(';');
            Connection.Open();
            using (OracleCommand com = Connection.CreateCommand())
            {
                for (int i = 0; i < sqls.Length; i++)
                {
                    com.CommandText = sqls[i];
                    com.ExecuteNonQuery();
                }
            }
            Connection.Dispose();
            CloseConn();
        }
    }
}