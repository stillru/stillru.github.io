---
layout: post
title: Как создать man для deb-пакета
description:
categories:
- it
---

Восстонавливаем блог :-)

Занялся я тут на досуге созданием deb пакета для [telegram-cli](https://github.com/vysheng/tg).

Вариантов создания deb пакета несколько.

## Checkinstall

Тут всё просто

```
./configure

./make

sudo checkinstall
```

Но это при условии что в секции `Makefile` есть инструкция `install`. В нашем случае её нету. Да и хтелось добавить пару файлов к пакету. Например упомянутые выше man-странички.

## Debianisation

Тут всё веселее.
