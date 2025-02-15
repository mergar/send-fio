## send-fio

Пакет скриптов для запуска (в ручном или автоматическом режиме) FIO тестов для оценки производительности I/O дисковой подсистемы.

Возможности:

 - тестирование индивидуального RAW диска (не должен содержать данные, тк проверка RAW диска приводит к потере данных на нем);
 - тестирование файловой системы ( по точке монтирования );
 - вывод результатов и/или отправка/публикация данных на внешний self-hosted/сервис или https://perf.SpaceVM.ru/ ;

## Usage

Общий запуск осуществляется скриптом 'myb-perf-fio-run', который связывает два других скрипта (которые также можно вызвать отдельно):

 'myb-perf-fio-fioloop'  - генерация профиля теста для FIO, запуск 'fio'. В результате работы в текущем каталоге будет создана директория tests/XXX с результатами и логами fio
 'myb-perf-fio-send' - запаковка результатов tests/XXXX в архив и отправка на сервис perf.SpaceVM.ru (скрипт может быть переопределен/дополнен на кастом);

При запуске скрипта 'myb-perf-fio-run' сканируются доступные локальные диски. Если найден хотябы один локальные чистый (без данных) диск, он становится доступным
для тестирования напрямую, что позволяет получить номинальные физические I/O характеристики. В случае, если имеются локальные диски содержащие какие-либо данные,
с целью защиты уничтожения ценных данных скрипт по-умолчанию не позволяет выбрать эти диски для тестирования. Если вы уверены, что диски с данными можно
использовать для проведения тестирований (и потерять данные, которые расположены на этих дисках), можно использовать переменную окружения DESTROY_DISK_DATA=1, например:

```
env DESTROY_DISK_DATA=1 ./run
```

для использования диска для тестирования.

Если 'чистых' дисков нет и не использована переменная окружения DESTROY_DISK_DATA=1, скрипт предполагает проведение тестов на уже имеющихся смонтированных файловых системах,
по-умолчанию это каталог '/tmp'. В случае запуска пакета на SpaceVM кластере, скрипт автоматически просканирует имеющиеся datapool и будет предполагать тестирование
каждого из датапулов (но можно выбрать индивидуально).

Другие рабочие переменные окружения:

FIO_AUTO_PROFILE   - задавать название профиля для авто-теста, например: 'randread'. Может принимать значение 'all', что означает последовательный запуск всех возможных тестов.
                     По-умолчанию значение параметра не задано, что соответствует профилю 'manual' - интерактивный режим для выбора тестов в ручном режиме.

FIO_AUTO_RWMIXREAD - задать значение по-умолчанию параметра 'rwmixread', используемого в mixed тестах (с read/write нагрузкой). По-умолчанию - '50';

FIO_AUTO_BS        - задать значение по-умолчанию параметра 'bs', по-умолчанию: '4k';

PERF_SPACEVM_SEND  - если установлен в '0' - не выполнять скрипт 'send-fio' и тем самым не высылать результаты на сервис perf.SpaceVM. По-умолчанию PERF_SPACEVM_SEND=1 - слать;

FIO_OFFLINE_MODE   - если установлен в '1' - не пробовать получать список профилей с checkin сервера;

SENDFIO_DEBUG      - уровень вербозности ( '1' по дефолту. Другие возможности: '0' - минимальный вывод, critial only, '1' - info вывод, '2' - включение sh xtrace );

Чтобы протестировать конкретный mountpoint:

```
myb-perf-fio-run /mnt/tmp
```


## Hooks

Вы можете встроить собственные сценарии для обработки факта начала тестирования и результатов через hook-каталог -- поместите в соответствующем каталоге executable скрипты и 
используйте переменные окружения для интеграции send-fio с любыми внешними сервисами ( отправка результатов в чат, БД и тп ):

/usr/local/share/myb/hooks.d/post.d - скрипты данного каталога выполняются после каждого теста, переменные содержат профиль/характер нагрузки и базовые метрики-результаты для данного сценария;
/usr/local/share/myb/hooks.d/pre.d - скрипты данного каталога выполняется в конце всех тестов, суммированная информация по всем запускаемым в одной сессии итерациям;
/usr/local/share/myb/hooks.d/summary.d - скрипты данного каталога выполняются при запуске каждого теста до того, как будет дана I/O нагрузка на тестируемый носитель;

В качестве примера скрипта и переменных, которыми можно оперировать внутри кастомных скриптов в hooks.d каталоге, см.: 'share/hooks.d/post.d/fio-hook-example.sh'
