---
layout: default
title: Проекты
current_project: current_page_item
---
<div id="content" class="pad">
  <h1 class="pagetitle">Мои Проекты</h1>
  <div class="entry page clear">
    <p>Их не так много и в большинстве своём они размещаются на github.com :-)</p>
	<h2> Счётчик до дня рождения</h2>
	<p> считает время до секунды. Считается что я родился 18 апреля в 17:45 и 40 секунд. Про секунды не уверен но счётчик считает именно до этого времени. Написан на JAVASCRIPT. </p>
<p style="color:red"><script LANGUAGE="JAVASCRIPT">   
ccDayNow = new Date();   
ccDayThen = new Date("Apr 18 2011 17:45:40 GMT+0400")   
msPerDay = 24 * 60 * 60 * 1000 ;   
timeLeft = (ccDayThen.getTime() - ccDayNow.getTime());   
cc_daysLeft = timeLeft / msPerDay;   
daysLeft = Math.floor(cc_daysLeft);   
cc_hrsLeft = (cc_daysLeft - daysLeft)*24;   
hrsLeft = Math.floor(cc_hrsLeft);   
minsLeft = Math.floor((cc_hrsLeft - hrsLeft)*60);   
document.write( "Через "+daysLeft+" дн, "+hrsLeft+" часов "+minsLeft+" минут - Случится 27 лет как я хожу по этой знмле.");   
</script></p>
<p>
<a href="http://keith-wood.name/countdown.html">http://keith-wood.name/countdown.html</a>
</p>
</div>
</div>