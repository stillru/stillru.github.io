---
layout: post
title: Первое знакомство с PowerShell
categories:
- it
---
После всей мощи которую представляет в руки администратора bash, powershell выглядит достаточно блёкло. Однако нет худа без добра - у меня наконец-то добрались руки до изучения этой оболочки.

Ранее я пользовался связкой cgwin+bash-via-cmd. Сейчас я пробую использовать по максимуму windows программы.

Совсем без cgwin'a обойтись не получится, по этому я использую самый минимум из этого пакета - OpenSSH, Core.

Итак, прошла установка, можно начинать подстраивать шелл под себя. Стандартным шеллом в Windows 2003 R2 являентся CMD. Данный шелл не имеет возможности удалённого управления. Нас это не устраивает. Однако есть две альтернативы - CygWin и PowerShell.

На данный момент CygWIN не является нативным для Win-платформы. Так что будем использовать PowerShell+некоторые пакеты из CygWin. 

{% highlight bash %}
PS [0]>
{% endhighlight %}
Добро пожаловать в Shell. То что вы видите перед собой сейчас - это приглашение нового интерактивного шелла Windows.

В чём разница между интерактивным шелом и не интерактивным?

Разница в мелочах, как водится :-)

Первый момент это возможность автозавершения не только исполняемых файлов но и команд шелла, загруженных функций, и даже аргументов необходимых функциям.

Второй момент - хранение переменных внутри запущенной сессии. Тоесть я могу написать в начале сессии `$cred = Server\User1` и в дальнейшем вместо введения каждый раз пары Server\User1, просто вызывать переменную `$cred` и просто вводить пароль. А если я точно знаю что в моих скриптах мне часто требуется использовать авторизацию, я могу эту переменную просто занести в профиль сессии.

### Scripting

В первую голову нам требуется разрешить выполнение скриптов на данной машине. Для этого устронавливаем переменную в состояние `Unrstricted` (Не контролируемое). Для особо заботящихся о безопасности - `SelfSigned` (Самоподписанные). Таким образом в первом случае будут запускаться все скрипты, во втором - только подписанные сертификатом, установленным на данном компьютере.

Далее настраиваем удалённый доступ:

{% highlight bash %}
Enable-PSRemote
{% endhighlight %}

Данная команда опять же выполняется от имени администратора.

### Usecase

Теперь давайте рассмотрим возможности которые предоставляет PS для администратора. Вопервых это возможность проверки состояня процесса. Тут нам поможет команда Get-Process. 

{% highlight bash %}
if (-not (get-process notepad).responding) {kill -name notepad; notepad}
{% endhighlight %}

Данная строчка проверяет систему на "зависание" процесса notepad, и в случае если он завис, процесс убивается и запускается новый.

Вариантов использования - множество. В дальнейшем я буду писать и другие примеры использования - в теге `Tips&Tricks` :-)