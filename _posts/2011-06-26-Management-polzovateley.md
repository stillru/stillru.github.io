---
layout: post
title: Менеджмент пользователей
categories:
- it
---
Как инструмент для реализации управления пользователями был использован PowerShell.

Идея в том чтобы запускать скрипт с параметрами, который создаст пользователя на сервере.

Скрипт простой:
{% highlight bash %}    
import-csv ".\userlist.csv" | foreach-object {
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
        write-host "User created and add to groups: $group1 and $group2"
}
{% endhighlight %}

Вот такой вот скриптик. Данные берутся из `userlist.csv` который состоит из нескольких столбцов:
{% highlight bash %}
Name,Full_Name,Description,Password,Main_Group,Secondary_Group
1Test1,Test User,TestDescription,123,Users,Administrators
{% endhighlight %}

Как видно в этом файле представлены значения из которых потом будут собираться пользователи и добавляться в 2 группы - `Main_Group`,`Secondary_Group`. По моему стойкому убеждению - не стоит засовывать пользователя в огромное количество групп. Вполне достаточно двух.

Однако это для создания локального пользователя на сервере. У нас же пользователи будут создаваться в Active Directory. Забегая вперёд, скажу что скрипт будет очень похож на этот. Но это будет уже в следующей статье.