---
layout: post
title: Устанавливаем сервер Windows 2003
categories:
- tip_n_trick
---
Советы по обустрройству в PowerShell

Задача: Быстрый доступ к определённым областям диска без набора полного пути.

Решение: В PowerShell есть такая вещь как `PSDrive` - диск, доступный исключительно из PowerShell. Посмотреть все доступные диски можно командой `Get-PSDrive`.
<pre>
Name           Used (GB)     Free (GB) Provider      Root                                               CurrentLocation
----           ---------     --------- --------      ----                                               ---------------
Alias                                  Alias
B                                66.33 FileSystem    C:\Users\Still\GIT\PersonalPakag...
Blog                             66.33 FileSystem    C:\Users\Still\GIT\stillru.githu...                         _draft
C                  33.67         66.33 FileSystem    C:\                                                    Users\Still
cert                                   Certificate   \
D                  82.77         35.09 FileSystem    D:\
Env                                    Environment
Function                               Function
HKCU                                   Registry      HKEY_CURRENT_USER
HKLM                                   Registry      HKEY_LOCAL_MACHINE
P                                66.33 FileSystem    C:\Users\Still\GIT\PersonalPakag...
Variable                               Variable
WSMan                                  WSMan
</pre>

В даноом выводе нас интересует только диски `Blog` `P` и `B` - это диски созданные самим пользоветелем с помощью команд `New-PSDrive`.
<pre>
New-PSDrive B -PSProvider FileSystem -Root C:\Users\Still\GIT\PersonalPakage\Scripts\Bash -Scope Global
New-PSDrive P -PSProvider FileSystem -Root C:\Users\Still\GIT\PersonalPakage\Scripts\Powershell -Scope Global
New-PSDrive Blog -Psprovider FileSystem -Root C:\Users\Still\GIT\stillru.github.com\ -Scope Global
</pre>
Данные команды можно прописать в профиле и при каждом запуске консоли иметь быстрый доступ к этим директориям как к простым дискам с обозначениями `P:` `B:` и `Blog:` 
`New-PSDrive <алиас диска> -PSProvider <Кто даёт доступ> -Root <путь к корню нового диска> -Scope область доступности
</pre>