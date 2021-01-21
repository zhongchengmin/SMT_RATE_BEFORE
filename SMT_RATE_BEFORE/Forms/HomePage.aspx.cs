using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Data;
using Newtonsoft.Json;

namespace SMT_RATE_BEFORE.Forms
{
    public partial class HomePage : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            string flag=Request.QueryString["flag"];
            if (flag == "prod")
            {
                getProdInfo();//獲取料號數據
            }
            else if (flag == "query")
            {
                string date = Request.QueryString["date"];//日期
                string shift = Request.QueryString["shift"];//班別
                string line = Request.QueryString["line"];//線別
                string prod = Request.QueryString["prod"];//料號
                string checkStation = Request.QueryString["checkStation"];//檢測站點
                string backStation = Request.QueryString["backStation"];//回推站點
                getPersonPass(date, shift,line, prod, checkStation, backStation);
            }
            else if (flag == "line") {
                string className = Request.QueryString["class"];//課別
                getLineInfo(className);
            }
            
        }

        private void getPersonPass(string date, string shift,string line, string prod, string checkStation, string backStation)
        {
            string startTime = string.Empty;
            string endTime = string.Empty;
            string oldareaname = string.Empty;
            string product = string.Empty;
            string rn = string.Empty;

            if (shift == "白班")
            {
                rn = "where a.RN<19";
                startTime = date.Replace("-", "") + "073000";
                endTime = date.Replace("-", "") + "193000";
            }
            else {
                rn = "where a.RN>=19";
                startTime = date.Replace("-", "") + "193000";
                endTime = Convert.ToDateTime(date).AddDays(1).ToString("yyyyMMdd") + "073000";
            }


            //判斷回推站點
            if (string.IsNullOrEmpty(backStation))
            {
                oldareaname = checkStation;
            }
            else {
                oldareaname = backStation;
            }


            //判斷料號
            if (prod != "[\"ALL\"]" && !string.IsNullOrEmpty(prod) && prod!="[]")
            {
                product = " AND l.PRODUCTSPECNAME in(" + prod.Replace("[", "").Replace("]", "").Replace("\"","'") + ")";
            }

            //判斷線別
            if (line != "ALL")
            {
                line = " and l.LINEID='" + line + "'";
            }
            else {
                line = "";
            }

            string sql = @"select a.TIMEHOUR,a.username,a.userid,nvl(b.pass,0)pass,nvl(b.fail,0)fail from(
            select * from(
                SELECT
                replace(replace(lpad(ROWNUM, 2), ' ', '0'), '24', '00') st_hour,
                replace(replace(lpad(ROWNUM, 2), ' ', '0'),'24','00')|| ':30' hour,
                replace(replace(lpad(ROWNUM, 2), ' ', '0'),'24','00')|| ':30'||'~'||replace(replace(replace(lpad(ROWNUM+1, 2), ' ', '0'),'24','00'),'25','01')|| ':30' timehour,
                replace(lpad(CASE
                    WHEN ROWNUM >= 7  THEN ROWNUM
                    ELSE ROWNUM + 24
                END, 2), ' ', '0') rn
            FROM
                dual
            CONNECT BY
                ROWNUM <= 24
            )a,(
            select distinct eventusername username,eventuser userid    FROM
                lothistorysumbase l
            WHERE
                l.timekey >= '" + startTime + @"'
                AND l.timekey < '"+endTime+@"'
                AND l.factoryname = 'NHA-SMT'
                AND l.oldareaname ='" + oldareaname + @"'
                AND eventusername not like '%測試%'
                " + product +line+ @"
            )b " + rn + @"
            )a left join(
            select hour,username,userid,sum(pass)pass,sum(fail)fail from(
            SELECT
                l.eventusername   username,
                l.eventuser       userid,
                l.pass,
                l.fail,
                case when to_char(EVENTTIME,'mi')<30 then to_char(EVENTTIME-1/24,'hh24') else to_char(EVENTTIME,'hh24') end||':30' hour
            FROM
                lothistorysumbase l
            WHERE
               l.timekey >= '" + startTime + @"'
                AND l.timekey < '" + endTime + @"'
                AND l.factoryname = 'NHA-SMT'
                AND l.oldareaname ='" + oldareaname + @"'
                AND eventusername not like '%測試%'
                " + product +line+ @"
                )group by username,userid,hour
            )b on a.HOUR=b.HOUR and a.username=b.username
            order by a.username,a.RN";

            DBConnection.DBConnection conn = new DBConnection.DBConnection("FMMESRPT");
            DataTable dt = conn.ExcuteSingleQuery(sql).Tables[0];

            string data = string.Format("{{\"success\":true,\"data\":{0}}}", JsonConvert.SerializeObject(dt));
            Response.Clear();
            Response.ContentType = "text/plain";
            Response.ContentEncoding = System.Text.Encoding.UTF8;
            Response.Write(data);
            Response.End();
        }

        private void getProdInfo()
        {
            string sql = @"select distinct productspecname from productspec p    where 1=1 and p.ACTIVESTATE = 'Active'
            AND p.factoryname='NHA-SMT'
            order by  ProductSpecName";


            DBConnection.DBConnection conn = new DBConnection.DBConnection("FMMESRPT");
            DataTable dt = conn.ExcuteSingleQuery(sql).Tables[0];

            string data = string.Format("{{\"success\":true,\"data\":{0}}}", JsonConvert.SerializeObject(dt));
            Response.Clear();
            Response.ContentType = "text/plain";
            Response.ContentEncoding = System.Text.Encoding.UTF8;
            Response.Write(data);
            Response.End();
        }

        private void getLineInfo(string className)
        {
            string sql = @"select * from m_group where TEAM='" + className + @"'
            order by LINEID";

            DBConnection.DBConnection conn = new DBConnection.DBConnection("FMMESRPT");
            DataTable dt = conn.ExcuteSingleQuery(sql).Tables[0];

            string data = string.Format("{{\"success\":true,\"data\":{0}}}", JsonConvert.SerializeObject(dt));
            Response.Clear();
            Response.ContentType = "text/plain";
            Response.ContentEncoding = System.Text.Encoding.UTF8;
            Response.Write(data);
            Response.End();
        }
    }
}