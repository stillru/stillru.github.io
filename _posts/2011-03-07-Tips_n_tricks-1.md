---
layout: post
title: Tips n Tricks #1
categories:
- tips_n_tricks
---
Советы по обустрройству в PowerShell

Задача: Быстрый доступ к определённым областям диска без набора полного пути.

Решение: В PowerShell есть такая вещь как `PSDrive` - диск, доступный исключительно из PowerShell. Посмотреть все доступные диски можно командой `Get-PSDrive`.,
<pre>
Alias                                  Alias
B                                66.33 FileSystem    C:\Users\Still\GIT\PersonalPakag...
Blog                             66.33 FileSystem    C:\Users\Still\GIT\stillru.githu...                         _draft
P                                66.33 FileSystem    C:\Users\Still\GIT\PersonalPakag...
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
