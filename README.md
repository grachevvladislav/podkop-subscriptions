# Podkop Subscriptions

[![Сборка APK](https://github.com/grachevvladislav/podkop-subscriptions/actions/workflows/build.yml/badge.svg)](https://github.com/grachevvladislav/podkop-subscriptions/actions/workflows/build.yml)
[![Последний выпуск](https://img.shields.io/github/v/release/grachevvladislav/podkop-subscriptions)](https://github.com/grachevvladislav/podkop-subscriptions/releases/latest)

Дополнение для OpenWrt и LuCI, которое обновляет список подключений в секции
`main` Podkop. Добавь HTTPS-ссылки на подписки, настрой фильтры и расписание.
Модуль поддерживает текстовые и Base64-списки и передаёт ссылки установленному
движку sing-box для разбора.

## Установка одной командой

Для сборки под **OpenWrt 25.12, mediatek/filogic, aarch64_cortex-a53**
нужны уже установленный Podkop 0.7.24 с режимом **URLTest** в секции `main`
и движок с командой `sing-box tools decode-link`, например podkop-engine.
Обычный sing-box из репозитория OpenWrt может не содержать эту команду.

Подключись к своему роутеру по SSH и выполни от `root`:

```sh
wget -qO- https://raw.githubusercontent.com/grachevvladislav/podkop-subscriptions/3248d26fed2b1d334739373ebfb1abb2f648ada7/install.sh | sh
```

Установщик проверяет версию OpenWrt и архитектуру, скачивает два APK из
[последнего выпуска](https://github.com/grachevvladislav/podkop-subscriptions/releases/latest)
и сверяет SHA-256. Пакеты опубликованы в GitHub Releases, поэтому при установке
используется `apk add --allow-untrusted`. Исходник установщика доступен в
[`install.sh`](install.sh). Для OpenWrt с `opkg` эти APK не подходят.

Открой **Services → Podkop subscriptions** в LuCI, добавь источник и нажми
**Save**. Новый источник опрашивается автоматически. Для повторного опроса
всех включённых источников нажми **Update now**. Кнопка **Check configuration**
скачивает источники и проверяет кандидатную конфигурацию без применения.

Модуль управляет полем **URLTest Proxy Links** секции `main`. Если уже работает
старый обновлятор того же поля, отключи задачу старого обновлятора перед первым
применением. Исходные настройки и ссылки можно сохранить резервной копией.

## Как работают фильтры и обновление

- Фильтры применяются отдельно к каждой включённой подписке. `Include name regex`
  ограничивает список совпадениями. `Exclude name regex` и `Exclude country codes`
  исключают совпавшие записи. В предпросмотре исключённые строки идут первыми.
- Коды стран вводятся через пробел, например `RU DE`. Модуль ищет флаги в
  декодированных названиях серверов. Для `RU`, `US`, `DE`, `NL` и `FI`
  также проверяются известные варианты названий стран. IP и домены в поиске
  по стране не участвуют.
- Для одинакового результата в LuCI и на роутере используй выражения,
  совместимые с JavaScript и POSIX ERE, например `Berlin|Frankfurt` или
  `^🇷🇺`. Предпросмотр проверяет имена в браузере, а роутер использует `grep -E`.
- После фильтрации одинаковые подключения объединяются. Название сервера
  не влияет на сравнение. Разные ключи, транспорт или параметры остаются
  отдельными подключениями.
- `Retry through Podkop proxy` повторяет неудачную прямую загрузку через
  локальный HTTP-прокси Podkop, если он доступен.
- Если источник недоступен, обход продолжается и статусы остальных источников
  обновляются. Общий список сохраняется прежним при ошибке, пустом результате
  или невалидной конфигурации. Отдельные неразбираемые ссылки пропускаются.

## Сборка и проверка

`make test` проверяет синтаксис и структуру проекта. `make sdk-build` собирает
два APK через Docker/OpenWrt SDK и выгружает их в `bin/`.
`make test-openwrt` запускает проверки обновления и дедупликации в одноразовых
контейнерах с OpenWrt.

GitHub Actions проверяет изменения в `main` и pull request, собирает оба APK
и сохраняет их как артефакт. Для тега вида `v0.1.0-r2` workflow публикует
GitHub Release с пакетами и контрольными суммами. Версия тега должна совпадать
с версией обоих пакетов.

Локальный стенд с LuCI, Podkop и podkop-engine:

```sh
docker build -f docker/preview.Dockerfile -t podkop-luci-preview .
docker run -d --name podkop-luci-preview -p 127.0.0.1:8088:80 podkop-luci-preview
```

Открой [интерфейс LuCI](http://127.0.0.1:8088/cgi-bin/luci/admin/services/podkop-subscriptions)
и войди как `root` с паролем `podkop-preview`. Контейнер запускает отдельный
sing-box на loopback для проверки конфигурации и интерфейса. В нём не запускаются
DNS и правила прозрачной маршрутизации Podkop для всей сети.
