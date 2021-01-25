<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="DefectDesc.aspx.cs" Inherits="SMT_RATE_BEFORE.Forms.DefectDesc" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>不良詳情</title>
    <link href="../Styles/iview.css" rel="stylesheet" type="text/css" />
    <script src="../Scripts/vue.js" type="text/javascript"></script>
    <script src="../Scripts/axios.min.js" type="text/javascript"></script>
    <script src="../Scripts/iview.min.js" type="text/javascript"></script>
</head>
<body>
    <div id="app">
    <template>
        <i-table stripe border :columns="columns1" :data="data1" ref=table></i-table>
    </template>
    <div style="text-align:right;margin-right:5px">
         <i-button type="success" size="large" @click="exportData"><Icon type="ios-download-outline"></Icon>數據導出</i-button>
    </div>
    </div>

    <script>
        var app = new Vue({
            el: '#app',
            data:function(){
                return {
                    columns1: [
                    {
                        title: '條碼',
                        key: 'LOTNAME',
                        sortable: true,
                        align: 'center'
                    },
                    {
                        title: '工單',
                        key: 'PRODUCTREQUESTNAME',
                        sortable: true,
                        align: 'center'
                    },
                    {
                        title: '料號',
                        key: 'PRODUCTSPECNAME',
                        sortable: true,
                        align: 'center'
                    },
                    {
                        title: '異常描述',
                        key: 'DEFECTDESC',
                        sortable: true,
                        align: 'center'
                    }
                ],
                data1: []
                }
            },
            mounted: function () {
                this.loadData();
            },
            methods: {
                loadData: function () {
                    axios.get('DefectDesc.aspx?flag=detail').then(response=>{
                        if(response.data.data.length>0){
                            this.data1=response.data.data;
                        }
                    });
                },
                exportData:function(){
                    this.$refs.table.exportCsv({
                        filename: 'The original data'
                    });
                }
            }
        });
    </script>
</body>
</html>
