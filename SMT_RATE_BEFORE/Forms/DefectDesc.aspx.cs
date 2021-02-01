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
    public partial class DefectDesc : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            string date = HttpContext.Current.Request.Cookies["Date"].Value;//日期
            string shift = HttpContext.Current.Request.Cookies["shift"].Value;//班別
            string line = HttpContext.Current.Request.Cookies["line"].Value;//線別
            string prod = HttpContext.Current.Request.Cookies["prod"].Value;//料號
            string checkStation = HttpContext.Current.Request.Cookies["checkStation"].Value;//檢測站點
            string backStation = HttpContext.Current.Request.Cookies["backStation"].Value;//回推站點
            string USERID = HttpContext.Current.Request.Cookies["USERID"].Value;//用戶工號
            string TIMEHOUR = HttpContext.Current.Request.Cookies["TIMEHOUR"].Value;//時間間隔

            string flag=Request.QueryString["flag"];
            if (flag == "detail")
            {
                loadData(date, shift,line, prod, checkStation, backStation, USERID, TIMEHOUR);
            }
        }

        private void loadData(string date, string shift,string line, string prod, string checkStation, string backStation,string USERID,string TIMEHOUR)
        {
            string startTime = string.Empty;
            string endTime = string.Empty;
            string oldareaname = string.Empty;
            string product = string.Empty;

            //判斷班別
            if (shift == "白班")
            {
                startTime = date.Replace("-", "") + "073000";
                endTime = date.Replace("-", "") + "193000";
            }
            else {
                startTime = date.Replace("-", "") + "193000";
                endTime = Convert.ToDateTime(date).AddDays(1).ToString("yyyyMMdd") + "073000";
            }
            //判斷回推站點
            if (string.IsNullOrEmpty(backStation))
            {
                oldareaname = checkStation;
            }
            else
            {
                oldareaname = backStation;
            }
            //判斷料號
            if (prod != "[\"ALL\"]" && !string.IsNullOrEmpty(prod) && prod != "[]")
            {
                product = " AND l.PRODUCTSPECNAME in(" + prod.Replace("[", "").Replace("]", "").Replace("\"", "'") + ")";
            }

            //判斷線別
            if (line != "ALL")
            {
                line = " and l.LINEID='" + line + "'";
            }
            else
            {
                line = "";
            }

            string sql = @"select l.LOTNAME,l.PRODUCTREQUESTNAME,l.PRODUCTSPECNAME,d.DEFECTDESC FROM
    lothistorysumbase l,defectdetail d
WHERE
   l.timekey >= '" + startTime + @"'
    AND l.timekey < '" + endTime + @"'
    AND l.factoryname = 'NHA-SMT'
    AND l.oldareaname ='" + oldareaname + @"'
    AND l.EVENTUSER='" + USERID + @"'
    " + line + @"
    and case when to_char(l.EVENTTIME,'mi')<30 then to_char(l.EVENTTIME-1/24,'hh24') else to_char(l.EVENTTIME,'hh24') end||':30'='" + TIMEHOUR.Split('~')[0] + @"'
    AND d.timekey BETWEEN '" + startTime + @"' AND '" + endTime + @"'
    AND d.factoryname = 'NHA-SMT'
    AND d.oldareaname = '" + oldareaname + @"'
    AND d.revisit = 'N'
    AND d.majordefect = 'Y'
    AND l.LOTNAME=d.LOTNAME
    AND l.FAIL>0";

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