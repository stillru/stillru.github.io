---
layout: post
title: Добавление пользователей в Active Directory - Делаем в Powershell
categories:
- it
---
Возникла необходимость в добавлении пользователей в свеже установленную Active Directory на Windows 2008 R2 Server.

Поскольку последнее время меня активно радует Powershell, я решил воспользоваться этой возможностью.

Первое что требуется сделать - продумать структуру будущего домена.

Моя структура выглядит следующим образом:

{% highlight bash %}
Домен
- UO="Название офиса по территориальному признаку"
- - UO="Пользователи"
- - - UO="Название подразделения"
- - - - CN="Пользователь"
- - UO="Группы"
- - - CN="Группа"
- - UO="Компьютеры"
- - - CN="Компьютер"
{% endhighlight %}

Для создания структуры нам потребуется скрипт Get-AD.ps1 который можно найти по адресу powershell.nu

Кстати все скрипты которые я буду использовать и русифицировать можно найти там же.

Листинги скриптов я в этой статье приводить не буду - все их можно посмотреть [github'е](https://github.com/stillru/PersonalPakage/tree/master/Scripts/Powershell/AD-Scripts).

Итак. Первый скрипт который нам понадобится - [Get-AD.ps1](https://raw.github.com/stillru/PersonalPakage/master/Scripts/Powershell/AD-Scripts/Get-AD.ps1). Его я использовал без изменений.

Второй скрипт - создаёт группы и структуру домена - [Add-STUO.ps1](https://raw.github.com/stillru/PersonalPakage/master/Scripts/Powershell/AD-Scripts/Add-STUO.ps1). Скрипт проходит через файл в формате csv и ищет необходимые данные.

Тут следует рассказать про структуру файла csv.

{% highlight bash %}
Character, Position, Rank, Department, Species, Starship, Series, Location
Пупкин Василий,Directors,Финансовый Директор,Directors,Финансовый Директор,Рога и копыта Главный офис,Рога и копыта Главный офис,Устьзадрюпинск
{% endhighlight %}

Все данные изменены - у нас тут новый закон "О защите персональных данных" вступает в силу :-)).

В данном скрипте я дописал следующее:
{% highlight bash %}
		# Another connection
		$NewConnection2 = "LDAP://OU=Users,OU=" + $Series + ($Domain.Replace(".",",DC=")).Insert(0,",DC=")
		$NewOU2 = [adsi]$NewConnection2
		$CsvFile2 = Import-Csv $Csv
		$CsvFile2 | Select Department -unique | ForEach {
		$Dep = $NewOU2.Create("OrganizationalUnit", "ou=$Department")
		$Dep.SetInfo()

		$Dep.put("l", $Location)
		$Dep.put("Description", $Department)
		$Dep.setinfo()
		}
{% endhighlight %}

Соответственно строчка `$NewConnection2 = "LDAP://OU=Users,OU=" + $Series + ($Domain.Replace(".",",DC=")).Insert(0,",DC=")` создаёт новое подключение используя данные из переменных csv-файла. Потом создаётся переменная `$NewOU2`. В следующей строчке мы снова инициализируем csv-файл а затем импортируем данные в переменную `$Department` из которой следующей строчкой создаётся структурное подразделение `UO=$Department,OU=Users,UO=Рога и копыта Главный офис,DC=domain,DC=com`.

Вот и всё :-) Структура создана. Пользователей будем добавлять в следующий раз.