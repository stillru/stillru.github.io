---
layout: post
title: Первое знакомство с PowerShell
tag: powershell, thung
---
После всей мощи которую представляет в руки администратора bash, powershell выглядит достаточно блёкло. Однако нет худа без добра - у меня наконец-то добрались руки до изучения этой оболочки.

Ранее я пользовался связкой cgwin+bash-via-cmd. Сейчас я пробую использовать по максимуму windows программы.

Совсем без cgwin'a обойтись не получится, по этому я использую самый минимум из этого пакета - OpenSSH, Core.

Итак, прошла установка, можно начинать подстраивать шелл под себя. Стандартным шеллом в Windows 2003 R2 
являентся CMD. Данный шелл не имеет возможности удалённого управления. Нас это не устраивает. Однако есть две 
альтернативы - CygWin и PowerShell.

На данный момент CygWIN не является нативным для Win-платформы. Так что будем использовать PowerShell+некоторые 
пакеты из CygWin. 

Все настройки шелла хранятся в переменной $profile - файлом, аналогичном bashrc, и запускающимся перед получением приглашения в систему.

{% highlight bash %}
$CYDWIN = 'C:\CygWIN\bin' 	#Добавляем к переменной PATH запускаемые файлы CygWIN
$env:EDITOR = 'nano'		#Назначаем редактор по умолчанию

#
# Функция для добавления переменной в PATH
#

function script:append-path { 
   if ( -not $env:PATH.contains($args) ) {
      $env:PATH += ';' + $args
   }
}


append-path "$TOOLS"
append-path "$CYDWIN"

#
# Функции определеня вывода приглашения 
#

function shorten-path([string] $path) {
   $loc = $path.Replace($HOME, '~')
   # remove prefix for UNC paths
   $loc = $loc -replace '^[^:]+::', ''
   # make path shorter like tabs in Vim,
   # handle paths starting with \\ and . correctly
   return ($loc -replace '\\(\.?)([^\\])[^\\]*(?=\\)','\$1$2')
}

function get-adminuser() {
   $id = [Security.Principal.WindowsIdentity]::GetCurrent()
   $p = New-Object Security.Principal.WindowsPrincipal($id)
   return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function prompt {
   # Определение цветов
   $cdelim = [ConsoleColor]::DarkCyan
   if ( get-adminuser ) {
      $chost = [ConsoleColor]::Red
   } else {
      $chost = [ConsoleColor]::Green
   }
   $cpref = [ConsoleColor]::Cyan
   $cloc = [ConsoleColor]::Magenta
   # Вывод приглашения вида computer@user:path>
   write-host $env:username@([net.dns]::GetHostName().ToLower()) -n -f $chost
   write-host '{' -n -f $cdelim
   write-host (shorten-path (pwd).Path) -n -f $cloc
   write-host '}' -n -f $cdelim
   return ' '
}
{% endhighlight %}
Данный код формирует вывод шела очень похожий на привычных bash ^-)

В первую голову нам требуется разрешить выполнение скриптов на данной машине. Для этого устронавливаем 
переменную в состояние Unrstricted (не контролируемое). Для особо заботящихся о безопасности - SelfSigned 
(Самоподписанные). Таким образом в первом случае будут запускаться все скрипты, во втором - только подписанные 
сертификатом, установленным на данном компьютере.

Далее настраиваем удалённый доступ:

{% highlight bash %}
Enable-PSRemote
{% endhighlight %}

Данная команда опять же выполняется от имени администратора.

Теперь давайте рассмотрим возможности которые предоставляет PS для администратора. Вопервых это возможность 
проверки состояня процесса. Тут нам поможет команда Get-Process. Вспоминаем что в PS любой вывод является 
объектом с набором атребутов и тут же рождается идея о том что любой процесс можно идентифицировать не только по 
имени но и по статусу. Что даёт возможность убивать процессы типа zombe и запускать их заново командами 
kill-process & start-process. Ранее это было возможо только комбинацией VBS & командой cmd net.

Второй момент - сортировка и архивирование данных по дате создания.

Третий момент - авто очистка от старых аккаунтов, не заходивших более определённого времени.

Четвёртый момент - поиск и работа с файлами опять же по дате создания. Незнаю - возможно это было реализованно и 
ранее в CMD, но для меня эта проблема возникла только в уже в окружении PowerShell.
