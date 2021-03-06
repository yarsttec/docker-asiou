# О Docker-образе

Образ базируется на официальном дистрибутиве, доступном по адресу
`http://asiou.coikko.ru/static/update_version/www<VERSION>.zip`.
Из архива распаковывается только часть файлов, необходимых для работы,
так как он содержит большое количество "мусора", работоспособность
проверяется только на одной организации (ЯГК).

Из файлов, касающихся базы данных, оставляются только файлы обновления
начиная с 2018-го года, поэтому данный образ не подходит для первоначального
развёртывания БД.

Также образ содержит ряд дополнений, которые позволяют ускорить или
исправить рабоут АСИОУ. Основной упор делался на минимизацию взаимодействия
с базой данных, так как, если сервер СУБД находится не на той же машине
(что по-хорошему и должно быть), то увеличиваются задержки при запросах.
Например, увеличение на 2 мс при 1000 запросах, добавил 2 секунды
к обработке всего запроса, что плохо.


# Дополнения (патчи)

- Убрано использование `pysvn`, так как этого пакета нет для установки
  (да и применение его для обновления совсем неоправданно, очень странный
  функционал).

- Добавлен модуль кэширования запросов к СУБД `django-cacheops`, а также
  запущен локально демон Redis.
  Необходимость использования обоснована тем, что часто выполняется куча
  абсолютно одинаковых запросов, результаты которых не кэшируются
  на стороне кода, что очень странно.

- Исправлен код, выполняющий экспорт в Контингент. Данный функционал
  содержит много проблем, которые разработчики не могут заделать, но
  пока исправлена критическая часть, которая позволяет функционалу
  как минимум отработать на стандартных найстройках БД.

- Добавлено чтение параметров БД из переменных окружения, что очень актуально
  для контейнеров.

- Добавлена возможность включения логов (в частности запросов к БД) по
  переменной окружения.

- Изменено время жизни сессии пользователя до 2 дней.

- Добавлено второе подключение к СУБД с другим типом курсора (`SSCursor`),
  что позволит при выгрезке всей таблицы из БД не держать её в памяти процесса,
  это чуть увеличивает вермя выгрузки, но повышает адекватность при таблицах
  в несколько сотен мегабайт.

- Оптимизация выгрузки на вышестоящий уровень (оно же и ЦОиККО).
  Во-первых, используется второе подключение к БД и не требуется гигабайт+
  оперативной памяти на выгрузку данных (при больших таблицах).
  Во-вторых, сжатие данных в ZIP осуществляется внешней специализированной утилитой,
  что увеличивает скорость, а также даёт контроль над параметрами сжатия.
  В-третьих, отдача ZIP-фала пользователю идёт через Nginx, не нагружая
  при этом Python-процесс.

- Оптимизировоны функции генерации главной страницы из-под администратора,
  разнообразные проверки данных, которые создают необоснованную нагрузку
  на СУБД и процессор.

- Добавлено кэширование запросов для тестов ПАВ (1 час) на уровне Nginx,
  так как это функционал публичный и не требует авторизации.


# Использование

Установка и настройка Docker находится за пределами данного мануала,
предполагается, что он уже есть и работает. Существует Docker под
платформу Windows, но всё же рекомендуется работать на Linux-системе.

Данный образ запускает Nginx, Apache, Redis и Django. Nginx обрабатывает
HTTP-запросы на порту 8080, статические файлы отдаёт с диска, остальные запросы
проксирует через Apache в Django. Ожидается, что база данных будет
запущена за пределами образа. Redis используется для кэширования запросов к БД.

## Пример запуска БД

Можно использовать уже существующую инсталляцию MySQL или, например,
также запустить в контейнере. При использовании существующей БД для
дальнейших шагов потребуются данные из файла `db.ini`.

Развернуть контейнер с MySQL можно следующим путём:

- Сгенерировать надёжный пароль для пользователя `root`, далее вместо него
  будет использоваться `PaSwOrD`.
- Сгенерировать надёжный пароль для пользователя `asiou`, далее `AsiouPassword`.
- Запустить контейнер с MySQL следующей командой:
  ```
  docker run -d --name mysql --restart=unless-stopped \
    -e MYSQL_ROOT_PASSWORD=PaSwOrD \
    -e MYSQL_DATABASE=asiou \
    -e MYSQL_USER=asiou \
    -e MYSQL_PASSWORD=AsiouPassword \
    -v <DATADIR>/mysql:/var/lib/mysql \
    -p 3306:3306 \
    mysql:5.7
  ```
  Где `<DATADIR>` - директория на хосте для хранения БД, чтобы при перезапуске
  данные не потерялись.

Выше приведён очень простой и небезопасный, пример запуска, так как порт
базы дынных будет доступен снаружи, рекомендуется использовать приватные
сети для связки двух контейнров (см. документацию Docker).
Также пример не описывает первоначальную загрузку или инициализацию данных.


## Пример запуска контейнера с АСИОУ

Из параметров минимально нужно передать хост и пароль к базе данных, в данном
случае получится команда:
```
docker run -itd --name asiou --restart=unless-stopped \
  -e DATABASE_HOST=172.17.0.1 \
  -e DATABASE_PASSWORD=AsiouPassword \
  -p 80:8080 \
  yarsttec/asiou
```
где `172.17.0.1` адрес сервера БД.
Список возможных переменных окружения для настройки контейнера с АСИОУ см. ниже.

Вероятно, удобнее будет запускать обновление сразу при старте контейнера, для
это нужно добавить аргумент `update_and_start` к команде запуска:
```
docker run -itd --name asiou --restart=unless-stopped \
  -e DATABASE_HOST=172.17.0.1 \
  -e DATABASE_PASSWORD=AsiouPassword \
  -p 80:8080 \
  yarsttec/asiou update_and_start
```


# Сборка образа

На данный момент образ приложения разбит на два: базовый и само приложение.
Для собственной сборки образов рекомендуется воспользоваться файлами `build.sh`
для Linux машин и `build.ps1` (PowerShell) для сборки под Windows.


# Доступные переменные окружения запуска

- `ASIOU_OPTIONS`, base64-encoded содержимое файла `asiou/options.ini`.
  По умолчанию найстройки даны для использования в СПО.
- `ASIOU_DB_INI`, base64-encoded содержимое файла `asiou/db.ini`.
  Все необходимые параметры БД можно задать через переменные окружения ниже,
  но в каких-то моментах может потребоваться.
- `DATABASE_HOST`, хост MySQL (по умолчанию `127.0.0.1`).
- `DATABASE_PORT`, порт MySQL (по умолчанию `3306`).
- `DATABASE_NAME`, имя базы данных (по умолчанию `asiou`).
- `DATABASE_USER`, имя пользователя MySQL (по умолчанию `asiou`).
- `DATABASE_PASSWORD`, пароль пользователя MySQL.
- `DEBUG_ASIOU`, включение режима отладки для Django.
- `DEBUG_SQL`, включение логирования запросов к БД.
- `ASIOU_HTTPS_ONLY`, `true` если куки должны посылаться только через HTTPS.
- `ASIOU_DOMAIN`, домен для кук, по умолчанию пусто (любой).
- `DJANGO_SECRET_KEY`, сикретный ключ для Django, как гласит документация,
  им ни с кем нельзя делиться.
- `ASIOU_RID_EXPORT_CRON`, строка расписания формата cron, например,
  `"<минуты> <часы> * * *"` (время по UTC, -3 часа от MSK).


# Обновление

Перед обновлением на новую версию, как это и сказано в официальных документах,
желательно сделать бэкап базы данных, потому-что некоторые изенмения при
обновлении могут быть необратимы простыми способами.

Также лучше сохранить старый образ контейнера (дав ему другую метку), например:
```
docker image tag yarsttec/asiou:latest yarsttec/asiou:previous
```

Теперь скачаем новую версию образа с помощью команды:
```
docker pull yarsttec/asiou
```
Если ничего не было скачено и появилась надпись `Image is up to date`, то
новой версии ещё не появилось.

Далее необходимо завершить текущий контейнер:
```
docker stop asiou && docker rm asiou
```
Затем запустить обновление БД (если для запуска не используется параметр
`update_and_start`, в таком случае можно просто запустить):
```
docker run -it --rm \
  -e DATABASE_HOST=172.17.0.1 \
  -e DATABASE_PASSWORD=AsiouPassword \
  yarsttec/asiou update
```
и снова запустить рабочий контейнер на свежей версии образа.

Чтобы увидеть ход обновления можно посмотреть логи контейнера:
```
docker logs --follow asiou
```

## Восстановление на предыдущий образ контейнера

Чтобы сделать откат на предыдущий образ (например, если новый не работает),
нужно либо в команде запуска контейнера указать предыдущий образ
(`yarsttec/asiou:previous`), либо откатить основную метку образа обратно:
```
docker image tag yarsttec/asiou:previous yarsttec/asiou:latest
```

Затем завершить и удалить текущий контейнер, и запустить заново.

## Миграция с 7.5.9

Для миграция на версию 7.6 можно воспользоваться следующими командами:
  1. Аналогично запустить контейнер, но с параметром `shell`, что позволит
     выполнить произвольную команду в окружении приложения,
  2. Подгрузить скрипт со вспомогательными функциями,
  3. Запустить команды миграции БД
  ```
  docker run -it --rm \
    -e DATABASE_HOST=172.17.0.1 \
    -e DATABASE_PASSWORD=AsiouPassword \
    yarsttec/asiou shell
  ```
  Далее внутри контейнера выполнить:
  ```
  source $HOME/asiou/scripts/utils.sh
  $(get_mysql_cmd) < $HOME/asiou/sql/django_migrations.sql
  run_script "update" asiou --fake
  run_script "update"
  ```


# Работа с бэкапами

## Введение

В образе содержится ряд утилит позволяющих просто и безопасно создавать бэкапы
базы данных. Основной упор ставится на шифрование данных, для чего
используется пара открытого и закрытого ключа (RSA) и алгоритм AES-256.

Вы можете сгенерировать пару ключей самостоятельно или воспользоваться
командой из образа (RSA 4096 bits):
```
docker run -it --rm \
  -v <DATADIR>/asiou/backup:/srv/backup \
  yarsttec/asiou gen-backup-keys
```
После выполнения команды в директории `<DATADIR>/asiou/backup` появятся файлы:
- `asiou_backup_private_key.pem`, закрытый ключ, должен храниться в надёжном
  месте, потребуются для восстановления архива.
- `asiou_backup_public_key.pem`, открытый ключ, будет необходим при каждом
  создании бэкапа.

Открытый ключ можно оставить в данной директории и осуществлять её монтирование
при каждом запуске процесса бэкапа. Утилиты работы с бэкапами ожидают, что
будет подмонтирована директория `/srv/backup` с ключом, и в которой окажется
результат выполнения.

Во время выполнения бэкапа будет создан одноразовый случайный ключ на 256 бит,
с помощью которого будет осуществлено надёжное шифрование данных дампа БД.
В данном случае используется симметричное шифрование (aes-256-cbc),
это означает, что расшифровка будет происходить тем же ключём, и его нужно
надёжно защитить. Для чего будет использоваться предоставленный открытый ключ,
им будет зашифрован одноразовый ключ. Исходный вариант случайного
ключа будет удалён. Восстановить одноразовый ключ можно будет только
с помощью закрытого ключа (что и происходит во время восстановления дампа).


## Создание бэкапа

Для создания бэкапа можно воспользоваться командой:
```
docker run -it --rm \
  -v <DATADIR>/asiou/backup:/srv/backup \
  -e DATABASE_HOST=172.17.0.1 \
  -e DATABASE_PASSWORD=AsiouPassword \
  yarsttec/asiou backup
```

В результате выполнения в папке `<DATADIR>/asiou/backup` создастся файл вида
`backup_asiou_db_20180630_151124.tar`, где `20180630` дата создания бэкапа,
а `151124` время.

Содержимое архива бэкапа выглядит так:
```
backup_asiou_db_20180630_151124.tar:
 - info.txt                    <- Информация о версии OpenSSL и алгоритме
 - backup_asiou_db.key.enc     <- Зашифрованный одноразовый ключ
 - backup_asiou_db.sql.bz2.enc <- Дамп базы, сжатый и зашифрованный
 - backup_asiou_db.sha256      <- Контрольная сумма sha256 ключа и данных
 - backup_asiou_db.md5         <- Контрольная сумма md5 ключа и данных
```

После сжатия и шифрования дампа БД, происходит обратный процесс (расшифровка
и распаковка архива) для проверки на ошибки.
Также создаются файлы с контрольными суммами SHA256 и MD5 для проверки
целостности при дальнейшем восстановлении.

## Восстановление бэкапа

Для восстановления бэкапа процесс происходит аналогичным образом, но утилита
требует наличие приватного ключа в директории с данными, а также указание
имени файла при запуске.
```
docker run -it --rm \
  -v <DATADIR>/asiou/backup:/srv/backup \
  -e DATABASE_HOST=172.17.0.1 \
  -e DATABASE_PASSWORD=AsiouPassword \
  yarsttec/asiou restore backup_asiou_db_20180630_151124.tar
```

В процессе восстановления все текущие данные будут полностью перезаписаны.


# Запуск командной строки

Для запуска командной строки внутри работающего контейнера можно воспользоваться
командно Docker:
```
docker exec -it asiou /bin/bash
```

Если необходимо провести какие-то действия с базой данных или что-то потестировать
без запущенного контейнер, то можно воспользоваться следующей командой:
```
docker run -it --rm \
  -e DATABASE_HOST=172.17.0.1 \
  -e DATABASE_PASSWORD=AsiouPassword \
  -p 80:8080 \
  yarsttec/asiou shell
```


# ViPNet

Так как существуют проблемы с запуском ViPNet под Linux или просто необходимо
использовать текущую установку на другом хосте, можно попробовать направить
трафик через узел с запущенным ViPNet в доверенной сети.
Одним из простых вариантов для Windows-хоста с ViPNet будет запуск Nginx
(с поддержкой stream, 1.10+) и проксированием запросов от АСИОУ непосредственно
на нужный сервер.

Например, для работы с ЕПГУ конечную точку можно найти в параметре
`ASIOU_CLAIM_URL` в файле `asiou/claim/constants.py`. В зависимости от
разработчиков она может быть как DNS-именем, так и IP-адресом.


## Настройка Nginx

`ASIOU_CLAIM_URL` ссылается на `wsasiou.yarcloud.ru` как конечный хост
и порт `8443`. Создадим конфигурацию, которая скажет Nginx слушать такой же порт,
а все входящие запросы отправлять на реальный хост для ЕПГУ. В добавок для
безопасности ограничим доступ и разрешим делать запросы только с нужного IP.

```
stream {
  upstream asiou-claim-8443 {
    server wsasiou.yarcloud.ru:8443;
  }

  server {
    listen 8443;
    proxy_pass asiou-claim-8443;
    allow <Asiou_Host_IP>;
    deny  all;
  }
}
```


## Проксирование для DNS-имени

Для перенапраления запросов, когда они идут по имени хоста, достаточно добавить
статическую запись в `hosts`, для чего можно воспользоваться параметром
`--add-host` при запуске Docker-контейнера:

```
docker run -itd --name asiou --restart=unless-stopped \
  -e DATABASE_HOST=172.17.0.1 \
  -e DATABASE_PASSWORD=AsiouPassword \
  --add-host=wsasiou.yarcloud.ru:<ViPNet_Host_IP> \
  -p80:8080 yarsttec/asiou update_and_start
```

Всё, теперь все запросы от АСИОУ к `wsasiou.yarcloud.ru` будут уходить на Nginx.


## Проксирование для IP-адреса

Для работы той же схемы, но на основе IP-адресов необходимо воспользоваться
сетевым экраном (примеры даны для `iptables`).

В первую очередь нужно найти конечный адрес `ASIOU_CLAIM_URL`, например, им
может быть `10.186.14.131`, порт также будет 8443. Далее нужно добавить правило
DNAT для iptables:

```
iptables -t nat -A OUTPUT \
  -p tcp -d 10.186.14.131/32 --dport 8443 \
  -j DNAT --to-destination <ViPNet_Host_IP>:8443
```

Всё, теперь все пакеты к `10.186.14.131:8443` пойдут через Nginx.
В данном случае порт для `<ViPNet_Host_IP>` можно настрой любой другой
(не забыв внести правки в конфиг для Nginx).


### Macvlan

В случае, когда контейнер запущен на Docker-сети с Macvlan драйвером, подход
немного усложняется. Так как сетевой стек у такой сети не связан с хостовым,
а у контейнера нет каких-либо расширенных привелегий, то настраивать правила для
iptables придётся через `ip netns exec`. Для чего нужно немного подготовить
хостовую систему:
```
mkdir -p /var/run/netns
NSPID=$(docker inspect --format='{{ .State.Pid }}' "asiou")
rm -f "/var/run/netns/$NSPID"
ln -s "/proc/$NSPID/ns/net" "/var/run/netns/$NSPID"
```

Теперь можно вызывать команды `iptables` в неймспейсе контейнера, например,
`ip netns exec $NSPID iptables -L`.

Добавим необходимое правило перенаправления пакетов:
```
ip netns exec $NSPID iptables -t nat -A OUTPUT \
  -p tcp -d 10.186.14.131/32 --dport 8443 \
  -j DNAT --to-destination <ViPNet_Host_IP>:18443
```

Всё. Единственная проблема здесь это то, что такие манипуляции необходимо
проводить после каждого перезапуска контейнера (но они легко автоматизируются).


# Ошибки

Образ предоставляется как есть, автор не несёт ответственность за его работу
и какую-либо потерю данных, но делает всё возможное, что всё работало
стабильно. Если Вы нашли ошибку или желаете внести дополнение в образ -
раздел `Issues` окажется в самый раз. Любые ошибки, непосредственно
связанные с функционалом АСИОУ, направляйте на официальный форум -
http://forum.asiou.ru, автор образа никак не связан с авторами АСИОУ.


# TODOs

- Посмотерть Nginx Unit в качестве замены Apache2.
  https://www.nginx.com/blog/configuring-nginx-unit-for-production-applications-serving-django-project/
- Посмотреть на GnuPG для шифрования архивов.
