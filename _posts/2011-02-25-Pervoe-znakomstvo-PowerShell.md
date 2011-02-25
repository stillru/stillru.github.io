---
layout: post
title: Первое знакомство с PowerShell

---

После всей мощи которую представляет в руки администратора bash, powershell выглядит достаточно блёкло. Однако нет худа без добра - у меня наконец-то добрались руки до изучения этой оболочки.

Ранее я пользовался связкой cgwin+bash-via-cmd. Сейчас я пробую использовать по максимуму windows программы.

Совсем без cgwin'a обойтись не получится, по этому я использую самый минимум из этого пакета - OpenSSH, Core.

Итак, прошла установка, можно начинать подстраивать шелл под себя.

Все настройки шелла хранятся в переменной $profile - файлом, аналогичном bashrc, и запускающимся перед получением приглашения в систему.

{% highlight batch %}
$CYDWIN = 'C:\CygWIN\bin'
$env:EDITOR = 'apad'

#
# set path to include my usual directories
# and configure dev environment
#
function script:append-path { 
   if ( -not $env:PATH.contains($args) ) {
      $env:PATH += ';' + $args
   }
}


append-path "$TOOLS"
append-path "$CYDWIN"
#
# Define our prompt. Show '~' instead of $HOME
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
   # our theme
   $cdelim = [ConsoleColor]::DarkCyan
   if ( get-adminuser ) {
      $chost = [ConsoleColor]::Red
   } else {
      $chost = [ConsoleColor]::Green
   }
   $cpref = [ConsoleColor]::Cyan
   $cloc = [ConsoleColor]::Magenta

   write-host $env:username@([net.dns]::GetHostName().ToLower()) -n -f $chost
   write-host '{' -n -f $cdelim
   write-host (shorten-path (pwd).Path) -n -f $cloc
   write-host '}' -n -f $cdelim
   return ' '
}
{% endhighlight %}
Данный код формирует вывод шела очень похожий на привычных bash ^-)

