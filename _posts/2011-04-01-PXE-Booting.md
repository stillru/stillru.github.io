---
layout: post
title: PXE Booting
categories:
- it
---
Есть у меня загрузочная флешка на которой собраны несколько инструментов для загрузки Live систем. Knoppix, Slax, Alkid, Дистрибутив Windows XP SP3 и т. д.

Однажды я пришёл на работу без этой флешки. И возникла идея использовать встроенную фичу большинства сетевых плат - загрузку по сети, так называемую технологию PXE.

Идея заключается в том что при загрузке компьютера активизируется загрузчик сетевой карты и обращается к DHCP серверу, получает код загрузки по TFTP и загружает загрузчик в оперативную память. Возникает окно выбора загрузки ОС по сети. После выбора ОС происходит загрузка ос по NFS или SAMBA.

Нам понадобится DHCP-сервер, TFTP-сервер и NFS или SAMBA сервера.

Два первых сервера у меня уже были - всё строилось на FreeBSD 8.1 которая у нас работает как шлюз между нами и внешним миром. Это кстати один из минусов - загрузка по сети требует большого канала и когда начинается загрузка по сети, есть возможность того что скорость обмена данными между другими участниками и шлюзом сильно снизится.

В качестве загружаемых систем у нас будут использоваться Trinity, Partion Magic, FreeBSD booting и CloneZilla.
Самые продвинутые меня тут же спросят - зачем мне столько одинаковых дистрибутивов, которые выполняют практически одинаковые задачи?

Отвечаю - это Unix-way. Каздой задаче нужен свой инструмент. Trinity - прекрасный инструмент для решения Windows-проблем. Partion Magic - полноценный linux для поиска и решения не тривиальных проблем. FreeBSD booting - загрузка минимального окружения для начала установки FreeBSD. CloneZilla - готовый инструмент для копирования уже установленных систем.

С целями разобрались - начнём всё это реализовывать.

Первое что нам понадобится - это DHCP-сервер. В FreeBSD это `ics-dhcp`. Устанавливается через систему портов:

{% highlight bash %}
# cd /usr/ports/net/ics-dhcp
# make install clean
{% endhighlight %}

Для его настройки я использую `webmin` но можно настроить и через конфигурационные файлы.

Вот содержимое моего конфига:

{% highlight bash %}
# dhcpd.conf

default-lease-time 86400;
max-lease-time 864000;

log-facility local7;

subnet 192.168.1.0 netmask 255.255.255.0 {
	next-server 192.168.1.201;
	filename "pxelinux.0";
	range 192.168.1.1 192.168.1.127;
	option domain-name-servers 192.168.1.201;
	option domain-name "mega-lex.local";
	option routers 192.168.1.201;
	option broadcast-address 192.168.1.255;
	default-lease-time 86400;
	max-lease-time 864000;
<-- Skipped -->
{% endhighlight %}

Нас в данном файлик интересует строчка `filename "pxelinux.0"`. Что это и откуда взялось - ниже. Сейчас же я скажу тоько то что это исполняемый код сетевого загрузчика.

Во вторую очередь нам понадобится TFTP-сервер - он устанавливается по умолчанию и включается простым разкоментироваием строчки в `/etc/inetd.conf`. Там же можно и настроить корневую папку этого сервера.

Пункт третий - создание загрузчика, того самого которого мы прописали для загрузки всей подсети `192.168.1.0/24`.

По сути это простое копирование файлов немного модифицированных файлов стандартного загрузчика linux/unix. Существует даже целый проект `syslinux` с сайта которого можно скачать всё необходимое.

Нас интересует сам загрузчик и несколько файлов, ответственных за формирование меню, а так же некоторые функции загрузчика. Это файлы `gpxelinux.0`, `pxelinux.0`, `vesamenu.c32`, `reboot.c32` и `chain.32`.

В корневой папке tftpd создаем папку pxeboot.cfg, а внутри этой папки файл с именем default примерно следующего содержания:

{% highlight bash %}
ui vesamenu.c32
#Подгружаем возможность отображения картинки
menu title Utilities
#Название Меню
menu background wall.png
#Обозначаем картинку

label Boot from first hard disk
#Отображаемый элемент
localboot 0x80
#Собственно загрузка по жёсткого диска
  TEXT HELP
  * Skip any load OS's. Just boot from First Boot Device
  * Default
  ENDTEXT

label Clonezilla Live
MENU LABEL Clonezilla Live
KERNEL clone/vmlinuz1
APPEND initrd=clone/initrd1.img boot=live live-config noswap nolocales edd=on nomodeset ocs_live_run="ocs-live-general"  ocs_live_extra_param="" ocs_live_keymap="" ocs_live_batch="no" ocs_lang="" vga=788 nosplash fetch=http://192.168.1.127/filesystem.squashfs
#Тут стоит заметить что в данном конкретном случае загрузка происходит по HTTP и с другой машины в локальной сети - не с сервера DHCP
  TEXT HELP
  * Clonezilla live version: 1.2.6-59-i686. (C) 2003-2011, NCHC, Taiwan
  * Disclaimer: Clonezilla comes with ABSOLUTELY NO WARRANTY
  ENDTEXT

label pmagic
MENU LABEL Partition Magic
LINUX pmagic/bzImage
APPEND initrd=pmagic/initramfs edd=off noapic load_ramdisk=1 prompt_ramdisk=0 rw vga=791 loglevel=0 max_loop=256
#Стадартная загрузка через TFTP
  TEXT HELP
  * Partition Magic Linux - Partition Tool
  * Disclaimer: Some time used tool for Administrators
  ENDTEXT

label linux
menu label PLOP Linux
kernel ploplinux/kernel/bzImage
append initrd=ploplinux/kernel/initramfs.gz vga=1 nfsmount=192.168.1.201:/usr/home/still/tftpboot/ploplinux
#Пример загрузки с использованием NFS
  TEXT HELP
  * PLOP Linux
  * Disclaimer: Security tool
  ENDTEXT

label freebsd
menu label FreeBSD 8.2 Install
pxe boot/pxeboot
#Старт инсталляционного пакета FreeBSD
  TEXT HELP
  * Tool for installing FreeBSD
  * Disclaimer: Extremly used for Gateways
  ENDTEXT

label reboot
menu label Reboot
kernel reboot.c32
#Вызов команды перезагрузки
  TEXT HELP
  * Do nothing. Just reboot...
  ENDTEXT

PROMPT 1
#Выбор параметра по умолчанию
TIMEOUT 100
#Таймаут до старта
{% endhighlight %}

Таким образом структура папок у меня получилась следующая:

{% highlight bash %}
tftpboot
|-pxelinux.0
|-vesamenu.c32
|-reboot.c32
|-chain.c32
|-gpxelinux.0
|--clone
|  |-initrd1
|  ˪-vmlinuz1.img
|--pmagic
|  |-bzImage
|  ˪-initramfs
|--ploplinux
|  ˪-kernel
|    |-bzImage
|    ˪-initramfs
˪--boot
   ˪-pxeboot

{% endhighlight %}

Все перечисленные образы лежат либо в соответственно сконфигурированной системе (NFS, HTTP) или в папке TFTP-сервера.

Вот и всё :-)
