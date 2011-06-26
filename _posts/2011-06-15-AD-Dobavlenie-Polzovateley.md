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

В данном скрипте я дописал ещё одну функцию:

{% highlight bash %}
function Add-OU2 ([string]$Domain, [string]$Series, [string]$Location, [string]$Department) {
    $distinguishedName = "OU="+ $Department + ",OU=Users,OU="+ $Series + ($Domain.Replace(".",",DC=")).Insert(0,",DC=")
        Check-distinguishedName -Domain $Domain -OU $distinguishedName
    if ($distinguishedNameDoesntExist -eq $True){
    # Новое подключение
    $NewConnection2 = "LDAP://OU=Users,OU=" + $Series ($Domain.Replace(".",",DC=")).Insert(0,",DC=")
    $NewOU2 = [adsi]$NewConnection2
    $Dep = $NewOU2.Create("OrganizationalUnit", "ou=$Department")
    $Dep.SetInfo()
    $Dep.put("l", $Location)
    $Dep.put("Description", $Department)
    $Dep.setinfo()
    Write-Host "Added OU: $Department to Users in $Series" -ForegroundColor Green
} else 
    {
        Write-Host "OU: $Department in Users at $Series Already Exists" -ForegroundColor Yellow
    }

    # Очищаем значение переменной
    $Script:distinguishedNameDoesntExist = $False
  }

{% endhighlight %}

Функция абсолютно идентична первоначальной но с одним отличием - она создают ещё один уровень в нашей структуре домена. 

{% highlight bash %}
$distinguishedName = "OU="+ $Department + ",OU=Users,OU="+ $Series + ($Domain.Replace(".",",DC=")).Insert(0,",DC=")
{% endhighlight %}

В этой строчке мы задаём значение переменной `$distinguishedName` соответственно нашей задаче.
{% highlight bash %}
Check-distinguishedName -Domain $Domain -OU $distinguishedName
    if ($distinguishedNameDoesntExist -eq $True)
{% endhighlight %}

Проверка на существование и вход в цикл.

Остальная часть функции описана точно так же как и в первой функции.

Однако есть ещё один момент - поскольку эта функция новая и не где не используется в скрипте, то надо её поместить после вызова первой функции:
{% highlight bash %}
Add-OU -Domain $Domain -Series $_.Series -Starship $_.Starship -Location $_.Location
Add-OU2 -Domain $Domain -Series $_.Series -Department $_.Department -Location $_.Location
{% endhighlight %}
Вот и всё :-) Структура создана. Пока я не разобрался со вложенными циклами и поэтому этот скрипт обладает излишней сложностью, но он работает. Пользователей будем добавлять в следующий раз.