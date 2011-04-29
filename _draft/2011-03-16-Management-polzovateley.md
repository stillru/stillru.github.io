---
layout: post
title: Менеджмент пользователей
categories:
- it
---
Возникла идея - заводить всех пользователей в одном месте - на сервере, через консоль PowerShell. А уже оттуда - рассылаться на все остальные сервисы, требующие регистрации. Это и почта, и IP-телефония, и 1С.

Как инструмент для реализации данного функционала я выбрал PowerShell.

Идея в том чтобы запускать скрипт с параметрами, который создаст пользователя на сервере, пользователя в LDAP, пользователя в MySQL, создаст файл настроек для копоративного почтового клиента и отправит учётные с файлом настроек админу в почту. А так же внесёт необходимые изменения в базы MySQL сервера Nausoftphone.

Начнём мы с создания локальных пользователей.

{% highlight bash %}    
import-csv ".\userlist2.csv" | foreach-object {
[string]$ConnectionString = "WinNT://SEVER,computer" 
        $ADSI = [adsi]$ConnecionString 
        $User = $ADSI.Create("user",$name) 
        $User.SetPassword($_.Password) 
        $User.put("description",$_.Description)
        $User.SetInfo()
        $User.put("fullname",$_.Full_Name)
        $User.SetInfo()

[string]$group1 = $_.Main_Group
        write-host $name "created..."
        $name = $name
        write-host $group1 "selected..."
        sleep 10
        $objOU = [ADSI]"WinNT://SEVER/$group1,group"
        $objOU.add("WinNT://SEVER/$name")
[string]$group2 = $secondary_Group
        write-host $group2 "selected..."
        sleep 10
        $objOU = [ADSI]"WinNT://SEVER/$group2,group"
        $objOU.add("WinNT://SEVER/$name")
        write-host "User created and add to groups."
}
{% endhighlight %}

Вот такой вот скриптик. Данные берутся из `userlist2.csv` который состоит из нескольких столбцов:
{% highlight bash %}
Name,Full_Name,Description,Password,Main_Group,Secondary_Group
1Test1,Test User,TestDescription,123,Users,Administrators
{% endhighlight %}

Как видно в этом файле представлены значения из которых потом будут собираться пользователи и добавляться в 2 группы - `Main_Group`,`Secondary_Group`. По моему стойкому убеждению - не стоит засовывать пользователя в огромное количество групп. Вполне достаточно двух.

Следующий этап - добавление пользоватля в LDAP:
