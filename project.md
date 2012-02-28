---
layout: default
title: Проекты
current_project: current_page_item
---
*** Мои Проекты

Их не так много и в большинстве своём они размещаются на github.com :-)

== Счётчик до дня рождения

Cчитает время до секунды. Считается что я родился 18 апреля в 17:45 и 40 секунд. Про секунды не уверен но счётчик считает именно до этого времени. Написан на JAVASCRIPT.

<p style="color:red"><script LANGUAGE="JAVASCRIPT">
ccDayNow = new Date();
ccDayThen = new Date("Apr 18 2012 17:45:40 GMT+0400")
msPerDay = 24 * 60 * 60 * 1000 ;
timeLeft = (ccDayThen.getTime() - ccDayNow.getTime());
cc_daysLeft = timeLeft / msPerDay;
daysLeft = Math.floor(cc_daysLeft);
cc_hrsLeft = (cc_daysLeft - daysLeft)*24;
hrsLeft = Math.floor(cc_hrsLeft);
minsLeft = Math.floor((cc_hrsLeft - hrsLeft)*60);
document.write( "Через "+daysLeft+" дн, "+hrsLeft+" часов "+minsLeft+" минут - Случится 28 лет как я хожу по этой знмле.");
</script></p>

== Репозиторий Скриптов

Здесь же, на github'е я собираю скрипты на BASH и POWERSHELL. Они доступны по <a href="http://stillru.github.com/PersonalPakage/">этому адресу</a>. Со временем я допишу WiKi для этого проекта. Сейчас она доступна по <a href="http://github.com/stillru/PersonalPakage/wiki">этому адресу</a>.</p>

== Test for QR Code

</div></div>
