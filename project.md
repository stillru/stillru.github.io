---
layout: default
title: Проекты
current_project: current_page_item
---
<div id="content" class="pad">
  <h1 class="pagetitle">Мои Проекты</h1>
  <div class="entry page clear">
    <p>Их не так много и в большинстве своём они размещаются на github.com :-)</p>
<p>
<SCRIPT LANGUAGE="JAVASCRIPT">   
ccDayNow = new Date();   
ccDayThen = new Date("april 18, 2011")   
msPerDay = 24 * 60 * 60 * 1000 ;   
timeLeft = (ccDayThen.getTime() - ccDayNow.getTime());   
cc_daysLeft = timeLeft / msPerDay;   
daysLeft = Math.floor(cc_daysLeft);   
cc_hrsLeft = (cc_daysLeft - daysLeft)*24;   
hrsLeft = Math.floor(cc_hrsLeft);   
minsLeft = Math.floor((cc_hrsLeft - hrsLeft)*60);   
document.write( "Через "+daysLeft+" дн, "+hrsLeft+" часов "+minsLeft+" минуту - Случится мой День рождения :-)");   
    </SCRIPT></p>
<P>
<script type="text/javascript">
//######################################################################################
// Author: ricocheting.com
// Version: v2.0
// Date: 2011-03-31
// Description: displays the amount of time until the "dateFuture" entered below.

// NOTE: the month entered must be one less than current month. ie; 0=January, 11=December
// NOTE: the hour is in 24 hour format. 0=12am, 15=3pm etc
// format: dateFuture1 = new Date(year,month-1,day,hour,min,sec)
// example: dateFuture1 = new Date(2003,03,26,14,15,00) = April 26, 2003 - 2:15:00 pm

dateFuture1 = new Date(2011,3,18,17,45,3);

// TESTING: comment out the line below to print out the "dateFuture" for testing purposes
//document.write(dateFuture +"<br />");


//###################################
//nothing beyond this point
function GetCount(ddate,iid){

	dateNow = new Date();	//grab current date
	amount = ddate.getTime() - dateNow.getTime();	//calc milliseconds between dates
	delete dateNow;

	// if time is already past
	if(amount < 0){
		document.getElementById(iid).innerHTML="Now!";
	}
	// else date is still good
	else{
		years=0;days=0;hours=0;mins=0;secs=0;out="";

		amount = Math.floor(amount/1000);//kill the "milliseconds" so just secs

		years=Math.floor(amount/31536000);//years (no leapyear support)
		amount=amount%31536000;

		days=Math.floor(amount/86400);//days
		amount=amount%86400;

		hours=Math.floor(amount/3600);//hours
		amount=amount%3600;

		mins=Math.floor(amount/60);//minutes
		amount=amount%60;

		secs=Math.floor(amount);//seconds

		if(years != 0){out += (years<=9?'0':'')+years +" "+((years==1)?"year":"years")+", ";}
		if(days != 0){out += days +" "+((days==1)?"day":"days")+", ";}
		if(hours != 0){out += hours +" "+((hours==1)?"hour":"hours")+", ";}
		out += mins +" "+((mins==1)?"min":"mins")+", ";
		out += secs +" "+((secs==1)?"sec":"secs")+", ";
		out = out.substr(0,out.length-2);
		document.getElementById(iid).innerHTML=out;

		setTimeout(function(){GetCount(ddate,iid)}, 1000);
	}
}

window.onload=function(){
	GetCount(dateFuture1, 'countbox1');
	//you can add additional countdowns here (just make sure you create dateFuture2 and countbox2 etc for each)
};
</script>
<div id="countbox1"></div>

</P>
</div>
</div>