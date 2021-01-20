<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="HomePage.aspx.cs" Inherits="SMT_RATE_BEFORE.Forms.HomePage" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>SMT良率回朔報表</title>
    <link href="../Styles/iview.css" rel="stylesheet" type="text/css" />
    <link href="../Styles/HomePage.css" rel="stylesheet" type="text/css" />
    <script src="../Scripts/vue.js" type="text/javascript"></script>
    <script src="../Scripts/axios.min.js" type="text/javascript"></script>
    <script src="../Scripts/iview.min.js" type="text/javascript"></script>
</head>
<body>
    <div id="app">
        <nav class="navbar">
        <div class="navbar-header">
            <a>
                <img class="logo" src="../img/logo.jpg" /></a>
            <a class="navbar-brand">SMT良率回朔報表</a>
        </div>
        </nav>
     <div class="form">
     <row>
        <i-col span="6">
            <label>日期：</label>
            <date-picker type="date" placeholder="請選擇日期" format="yyyy-MM-dd" style="width: 200px" v-model="defaultDate"></date-picker>
        </i-col>
        <i-col span="6">
            <label>班別：</label>
            <i-select v-model="shift" style="width:200px">
                <i-option value="白班">白班</i-option>
                <i-option value="晚班">晚班</i-option>
            </i-select>
        </i-col>
        <i-col span="6">
            <label>線別：</label>
            <i-select v-model="defaultLineValue" style="width:200px">
                <i-option value="ALL">ALL</i-option>
                <i-option v-for="item in lineInfo" v-bind:value="item.LINEID" v-bind:key="item.LINEID">{{item.LINEID}}</i-option>
            </i-select>
        </i-col>
        <i-col span="6">
            <label>機種：</label>
            <i-select v-model="defaultProdValue" style="width:300px" multiple filterable :max-tag-count="1">
                <i-option value="ALL">ALL</i-option>
                <i-option v-for="(item,index) in ProdInfo" v-bind:value="item.PRODUCTSPECNAME" v-bind:key="index">{{item.PRODUCTSPECNAME}}</i-option>
            </i-select>
        </i-col>
     </row>

       <row class="secondRow">
        <i-col span="6">
            <label>檢測站點：</label>
            <i-select style="width:200px" v-model="default_CheckStation" v-on:on-change="checkChange">
                <i-option v-for="item in checkStation" v-bind:value="item" v-bind:key="item">{{item}}</i-option>
            </i-select>
        </i-col>
        <i-col span="6">
            <label>回推站點：</label>
            <i-select v-model="backStationValue" style="width:200px">
                <i-option v-for="(item,index) in backStation" v-bind:value="item" v-bind:key="index">{{item}}</i-option>
            </i-select>
        </i-col>
        <i-col span="6">
            <label>課別：</label>
            <i-select v-model="defaultClassValue" style="width:200px" v-on:on-change="classChange">
                <i-option value="三課">三課</i-option>
                <i-option value="一課">一課</i-option>
                <i-option value="二課">二課</i-option>
            </i-select>
        </i-col>
        <i-col span="6">
            <i-button type="success" v-on:click="query">查詢</i-button>
        </i-col>
     </row>
     </div>
     <div class="container">
        <table>
            <tr>
                <td></td>
                <td v-for="item in userInfo" v-bind:key="item.USERNAME" v-html="item.USERNAME+'<br/>'+item.USERID"></td>
            </tr>
            <tr>
                <td>
                    TOTAL
                </td>
                <td v-for="(item,index) in personTotalPass" v-html="item['FAIL']+'<br/>'+item['PASS']" v-bind:key="index" v-bind:style="{'backgroundColor':decideColor(item['FAIL'],item['PASS'])}">
                </td>
            </tr>
            <tr v-for="item in timehour">
                <td>
                    {{item}}
                </td>
                <td v-for="(key,index) in passDetail(item)" v-html="key['FAIL']+'<br/>'+key['PASS']" v-bind:key="index" v-bind:style="{'backgroundColor':decideColor(key['FAIL']),'cursor':decideCursor(key['FAIL'])}" v-on:click="browseTo(key['FAIL'],key['TIMEHOUR'],key['USERID'])">
                   
                </td>
                
            </tr>
        </table>
     </div>
    </div>
    <script>
        var app = new Vue({
            el: '#app',
            data: function () {
                return {
                    shift: '',//班別選項值
                    backStationValue: '',//回推站點選項值
                    defaultDate:'',//日期選項值
                    ProdInfo:[],//機種數據
                    defaultLineValue: 'ALL',//線別選項值
                    defaultProdValue:'ALL',//機種選項值
                    defaultClassValue:'三課',//課別選項值
                    checkStation: ['SMT-MOUNT', 'SMT-REFIN', 'SMT-ICT', 'SMT-FT', 'SMT-ESD', 'SMT-FV'],//檢測站點
                    backStation: ['SMT-MOUNT', 'SMT-REFIN', 'SMT-ICT', 'SMT-FT', 'SMT-ESD'],//回推站點
                    default_CheckStation: 'SMT-FV',//檢測站點選項值
                    userInfo:[],//table第一行user數據
                    timehour:[],//時間範圍
                    passInfo:[],
                    lineInfo:[],//線別
                    personTotalPass:[],//人員匯總產出和匯總不良數據
                    cursor:'default'//鼠標樣式
                }
            },
            created: function () {
                this.getProdInfo();//請求料號數據
            },
            mounted: function () {
                this.decideShift();//判斷日期和班別
                this.getLineInfo(this.defaultClassValue);//請求線別數據
            },
            methods: {
                //判斷白晚班
                decideShift: function () {
                    var date = new Date();
                    var fromDate = new Date(date.getFullYear() + '-' + (date.getMonth() + 1) + '-' + date.getDate() + ' 07:30:00');
                    var endDate = new Date(date.getFullYear() + '-' + (date.getMonth() + 1) + '-' + date.getDate() + ' 19:30:00');
                    if (date > fromDate && date < endDate) {
                        this.shift = '白班'
                    } else {
                        this.shift = '晚班'
                    }
                    //設定日期
                    if(date<fromDate){
                        var datetime = date.setDate(date.getDate()-1);
                        var newDate = new Date(datetime);
                        this.defaultDate=newDate.getFullYear() + '-' + (newDate.getMonth() + 1) + '-' + newDate.getDate();
                    }else{
                        this.defaultDate=date.getFullYear() + '-' + (date.getMonth() + 1) + '-' + date.getDate();
                    }
                },//選擇檢測站點觸發的事件
                checkChange: function (val) {
                    var index = this.checkStation.indexOf(val); //找到檢測站點的坐標
                    this.backStation = this.checkStation.slice(0, index);
                    this.backStationValue = ''; //每選擇一個檢測站點就把回推站點選項清空掉
                },//選擇課別觸發的事件
                classChange:function(val){
                    if(val=="三課"){
                        this.checkStation=['SMT-MOUNT', 'SMT-REFIN', 'SMT-ICT', 'SMT-FT', 'SMT-ESD', 'SMT-FV'];
                        this.backStation=['SMT-MOUNT', 'SMT-REFIN', 'SMT-ICT', 'SMT-FT', 'SMT-ESD'];
                        this.default_CheckStation='SMT-FV'
                    }else if(val=="一課"){
                        this.checkStation=['DIP-HEAD', 'DIP-REFIN', 'DIP-RT', 'DIP-TV', 'DIP-FV'];
                        this.backStation=['DIP-HEAD', 'DIP-REFIN', 'DIP-RT', 'DIP-TV'];
                        this.default_CheckStation='DIP-FV'
                    }
                    this.getLineInfo(val);
                },//請求料號數據
                getProdInfo: function () {
                    axios.get('HomePage.aspx', {params:{ 'flag': 'prod' }}).then(response=>{
                        if(response.data.data.length>0){
                            this.ProdInfo=response.data.data;

                            this.$nextTick(()=>{
                                this.query();
                            });

                        }else{
                            this.ProdInfo=[];
                        }
                    });
                },//請求線別數據
                getLineInfo:function(val){
                    axios.get('HomePage.aspx',{params:{'flag':'line','class':val}}).then(response=>{
                        this.lineInfo=response.data.data;
                    });
                },
                passDetail:function(val){
                    return this.passInfo.filter((item)=>{
                        return item['TIMEHOUR']==val;
                    });
                },//請求產出defect數據
                getPersonPass:function(date,shift,line,prod,checkStation,backStation){
                     var user={};
                     var timehour=new Set();
                        axios.get('HomePage.aspx', {params:{
                             'flag': 'query',
                            'date':date,
                            'shift':shift,
                            'line':line,
                            'prod':prod,
                            'checkStation':checkStation,
                            'backStation':backStation
                            }}).then(response=>{

                        if(response.data.data.length>0){
                            this.passInfo=response.data.data;
                            response.data.data.forEach((item,index)=>{
                                user[item['USERNAME']]=item['USERID'];
                                timehour.add(item['TIMEHOUR']);
                            });
                            this.timehour=Array.from(timehour);
                            this.userInfo=[];//添加用戶信息數據之前先清空
                            for(var item in user){
                                this.userInfo.push({
                                    'USERNAME':item,
                                    'USERID':user[item]
                                });
                            }
                            this.totalPass();
                        }else{
                            this.passInfo=[];
                            this.userInfo=[];
                            this.personTotalPass=[];
                            this.timehour=[];
                        }
                    });
                },
                totalPass:function(){
                    this.personTotalPass=[];//添加用戶產出不良加總數據之前先清空
                    this.userInfo.forEach((item)=>{
                        var pass=0;
                        var fail=0;
                        var person={};
                        this.passInfo.forEach((item2)=>{
                            if(item["USERNAME"]==item2["USERNAME"]){
                                pass+=item2["PASS"];
                                fail+=item2["FAIL"];
                            }
                        });
                        person['USERNAME']=item["USERNAME"];
                        person['PASS']=pass;
                        person['FAIL']=fail;
                        this.personTotalPass.push(person);
                        pass=0;
                        fail=0;
                        person={};
                    });
                },
                decideColor:function(...args){
                    if(args.length>1){
                        var rate =1- args[0]/args[1];
                        if(rate<0.97){//良率小於97%變紅色
                            return 'red'
                        }else if(rate>0.97&&rate<1){
                            return 'orange'
                        }
                    }else{
                        if(args[0]>=1){
                            return 'red'
                        }
                    }
                    return '#3ADA3A';
                },
                decideCursor:function(val){
                    if(val>=1){
                         return 'pointer'
                     }
                },
                isZero:function(val){
                    if(val<10){
                        return '0'+val;
                    }else{
                        return val;
                    }
                },
                browseTo:function(val,TIMEHOUR,USERID){
                    if(val>=1){
                         var date = new Date();
                        date.setTime(date.getTime() + 60 * 60 * 1000);
                        document.cookie = "Date=" + this.defaultDate.getFullYear()+'-'+this.isZero(this.defaultDate.getMonth() + 1)+'-'+this.isZero(this.defaultDate.getDate()) + ";expires=" + date.toGMTString() + "";
                        document.cookie = "shift=" + this.shift+ ";expires=" + date.toGMTString() + "";
                        document.cookie = "line=" +this.defaultLineValue+ ";expires=" + date.toGMTString() + "";
                        document.cookie = "prod=" +JSON.stringify(this.defaultProdValue)+ ";expires=" + date.toGMTString() + "";
                        document.cookie = "checkStation=" + this.default_CheckStation+ ";expires=" + date.toGMTString() + "";
                        document.cookie = "backStation=" + this.backStationValue+ ";expires=" + date.toGMTString() + "";
                        document.cookie = "TIMEHOUR=" + TIMEHOUR+ ";expires=" + date.toGMTString() + "";
                        document.cookie = "USERID=" + USERID+ ";expires=" + date.toGMTString() + "";
                        window.open('DefectDesc.aspx','_blank');
                    }
                },
                //查詢
                query:function(){
                    var date=this.defaultDate.getFullYear()+'-'+this.isZero(this.defaultDate.getMonth() + 1)+'-'+this.isZero(this.defaultDate.getDate());//日期
                    var shift=this.shift;//班別
                    var prod=JSON.stringify(this.defaultProdValue);//料號
                    var checkStation=this.default_CheckStation;//檢測站點
                    var backStation=this.backStationValue;//回推站點
                    var line=this.defaultLineValue;//線別
                       
                    this.getPersonPass(date,shift,line,prod,checkStation,backStation);
                },
                test:function(val){
                    console.log(this.personTotalPass);
                }
            }
        })
    </script>
</body>
</html>
