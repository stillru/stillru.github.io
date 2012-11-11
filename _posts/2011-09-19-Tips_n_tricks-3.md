---
layout: post
title: Tips n Tricks #3
categories:
- tips_n_tricks
---
### PSRemoting

Как заставить работать удалённое управление в PowerShell?

У меня есть несколько серверов под Windows 2008 R2 и хочется иметь возможность к ним подключаться.

Делаем так:

        На сервере запускаем Enable-PSRemoting от имени администратора
        делаем set-item wsman:localhost\client\trustedhosts -value * # это для подключения с любого компьютера
        PROFFIT!!!!
		
Ничего страншго в этом нет. Только я вместо звёздочки везде пишу имя своего ноутбука.