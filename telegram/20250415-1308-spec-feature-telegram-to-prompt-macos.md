# Intro
Суть идеи, что у меня уже есть [[=._TDL-Golang-Repository]], последнее что помню например бэкапил [[20250402-Task-Extract-Dossiers-Members-of-Groups-based-on-Messages]] ([[20250402-Json-Raw-Group-files-big]]), и там например надо быстро подтянуть переписку группы или с человеком
- [[tdl-extended-commands-for-test-scenarios]], [[archive/old-docs/_docs2/tests/tdl-extended-commands-for-test-scenarios]], 

короче не те доки но суть я просто быстро пишу, я могу что-то типо `tg2p shimanskij 7d` or `tg2p shimanskij all`, `tg2p shimanskij 100`, `tg2p ilya 7d`
1. `username` (shimanskij) || `alias` (мой другй ilya c crpt_member) быстрее иногда писать и непомнить ники, это брать из contacts.csv и подставлять нужный chatID
	1. такая же логика для групп по `alias || username`
	2. contacts.csv у меня есть, и там колонка alias; 
2. 7d - d days, еще можно w - weeks, m - months, y - years, h - hours - само считает и добавляет с фильтро -T 
3. `100` - если нет после цифры буквы это штук особщений - само считает и добавляет с фильтро -T last что-то там
4. voice by default
5. как сохранять? очевидно перезаписывать если фильтр одинаковые и отражать условно команды в filename
	1. каждый контакт папка `./<id>-<username>`
6. еще была идея чтобы не делать дубли там условно в подпапку `/.duplicates/*` делать папку и смотреть по маске родителя самого полного типо если будет `<id>-shimanskij-all.md` то его, а тот в подпапку `<id>-shimanskij-7d.md`

# How to code?
1. я могу вернуться к той функции и дорабатывать ее в ветке markdown, но там ошибка да и не хочется go-lang делать проще я буду юзать уже кое как рабочее с voice-to-text-<4min
2. и скрипт `/Users/user/__Repositories/LLMs-AssistantTelegram-ChatRag__SecondBrainInc/scripts/tgJson2Markdown/tgJson2Markdown.py` передалаю под мои нужды

# Coding
## Automation extract in markdown message history
- [x] выбрать Андрея как тестового и сделать следующие команды в Raw [[tdl-]]
	- [x] store path logic is 
		- [x] JSON raw files is here and mostly never deleted, I'll explained detailed. 
			- [x] check how I handle filename for markdown files, it's the same
			- [x] and I don't need them to move "mv %file% .tg-archives/", it always should be stored in a `/Users/user/NextCloud2/__Vaults_Databases_nxtcld/__People_nxtcld/telegram/%namespace%_messages_raw-%options%.json`
		- [x] Markdown files in a `/Users/user/____Sandruk/___PKM/__Vaults_Databases/__People__vault/%namespace%`
			- [x] for user which doesn't have a telegram `%tg_username%` we check just `%tg_id%` (which actually is equal `%chatID%`)
			- [x] maskname is `@._%tg_username%-tg_id-%tg_id%-%could-be-any-my-text-later-don't-touch-it%-%optionally:-7d-all-100-1y%`, let me show an examples `@._@shimanskij-tg_id-508519898-Andrei-Shimanskij-HappyAI-7d.md` and if I later run for e.g. `tg2p shimanskij all` it creates `@._@shimanskij-tg_id-508519898-Andrei-Shimanskij-HappyAI-ALL.md` 
				- [x] BUT DON't DELETE `@._@shimanskij-tg_id-508519898-Andrei-Shimanskij-HappyAI-7d.md`, it makes `mv @._@shimanskij-tg_id-508519898-Andrei-Shimanskij-HappyAI-7d.md .tg-archives/` sub-folder starts from dot tg-archives, why I need it ? I don't want to have duplicates in obsidian.
					- [x] how to decide why 7d? what is the idea of parenting? the most common should be store, others move to archive. Is it logic. isn't it? How to determin? by mask names in the 3nd with kebab case -7d and other shortings.

## Скрипт tg2p (Telegram to Prompt)
- [x] Создан скрипт `/Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/telegram/messages-tg2prompt-telegram-retriever-handler-tdl-manager.py`
- [x] Функциональность:
  - [x] Парсинг аргументов командной строки `tg2p <identifier> <time_spec>`
  - [x] Поиск контакта в CSV файлах в директории `/Users/user/____Sandruk/___PKM/__Vaults_Databases/__People__vault/DatabaseContacts`
  - [x] Определение нужного namespace для TDL на основе найденного контакта
  - [x] Генерация и выполнение команды TDL с правильными параметрами
  - [x] Сохранение JSON выходных данных в `/Users/user/NextCloud2/__Vaults_Databases_nxtcld/__People_nxtcld/telegram`
  - [x] Конвертация JSON в markdown с помощью скрипта `tgJson2Markdown.py`
  - [x] Архивация старых markdown файлов для того же контакта

### Работа с форматами времени
- [x] `7d` - 7 дней (использует фильтр `-T time`)
- [x] `2w` - 2 недели (использует фильтр `-T time`)
- [x] `1m` - 1 месяц (использует фильтр `-T time`)
- [x] `1y` - 1 год (использует фильтр `-T time`)
- [x] `12h` - 12 часов (использует фильтр `-T time`)
- [x] `100` - последние 100 сообщений (использует фильтр `-T last`)
- [x] `all` - все сообщения (использует фильтр `-T time` с большим диапазоном)

### Обработка файлов
- [x] Создание уникальных имен файлов на основе информации о контакте и временной спецификации
- [x] Архивация старых markdown файлов в подпапку `.tg-archives` для избежания дубликатов в Obsidian
- [x] Сохранение всех raw JSON файлов без перемещения их в архив

### Работа с TDL
- [x] Всегда использует опции `--with-content --all --raw --transcribe-voice`
- [x] Обработка различных временных спецификаций для правильных фильтров TDL
- [x] Обработка ошибок при выполнении команды TDL

### Работа с контактами
- [x] Поиск контактов в CSV файлах с шаблоном `telegram-*-contacts-chats-list.csv`
- [x] Извлечение namespace из названия файла контактов
- [x] Соотнесение username или ID с правильным chat_id и namespace

## Auto contacts.csv retriever on my macos
- [ ] make a script `/Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/telegram/contacts-periodic-updater-csv-telethon-manager.py` + use app `/Users/user/__Repositories/tg-combainer__developerisnow/src_python/main.py` (README `/Users/user/__Repositories/tg-combainer__developerisnow/README.MD`)
	- [ ] path to store all `telegram-%namespace%-contacts-chats-list.csv` is `/Users/user/____Sandruk/___PKM/__Vaults_Databases/__People__vault/DatabaseContacts`
	- [ ] we checked path with existing authorized sessions and do each one by one sequentially, for now it's 12 %namespaces% sessions, in future around 25
```bash
user@Mac tg-combainer__developerisnow % cd /Users/user/__Repositories/tg-combainer__developerisnow/env/tg_sessions
user@Mac tg_sessions % pwd
/Users/user/__Repositories/tg-combainer__developerisnow/env/tg_sessions
user@Mac tg_sessions % tree
.
├── alex_france.session
├── crispr_cas9_ceo.session
├── cryptoperceptron copy.session
├── cryptoperceptron.session
├── freelifexplorer.session
├── herewegohereiam.session
├── ittechguru.session
├── mindspace0.session
├── mitch_no_username.session
├── singularity_explorer.session
├── usernyme.session
└── watchterbotguard.session

0 directories, 12 files
user@Mac tg_sessions % 
```
- [ ] attention some accounts has 2 or even 10K chats and processing could be around 2-5-10 minutes need wait and when it done do next.
- so first need to 
- [ ] upgrade EXISTING APP to support option run with %namespace% and check folder of it `env/tg_sessions/*.` need to add as a separate module/function it to handling this behaivour of existing code `/Users/user/__Repositories/tg-combainer__developerisnow/src_python/*`
- [ ] write a script `/Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/telegram/contacts-periodic-updater-csv-telethon-manager.py` which just run it and store logs of stdout script, wait when one %namespace% finish then run next. Do it each hour if macos is turn on.

# Использование скрипта tg2p

## Примеры команд
```bash
# Получить сообщения за последние 7 дней от shimanskij
tg2p shimanskij 7d

# Получить все сообщения от shimanskij
tg2p shimanskij all

# Получить последние 100 сообщений от shimanskij
tg2p shimanskij 100

# Получить сообщения за последний месяц от пользователя по имени ilya
tg2p ilya 1m

# По умолчанию, если не указан временной интервал, используется 1 день
tg2p shimanskij
```

## Параметры командной строки
```
usage: messages-tg2prompt-telegram-retriever-handler-tdl-manager.py [-h] [--tdl-path TDL_PATH] 
                                                                   [--contacts-dir CONTACTS_DIR]
                                                                   [--raw-json-dir RAW_JSON_DIR]
                                                                   [--markdown-dir MARKDOWN_DIR]
                                                                   [--log-level {DEBUG,INFO,WARNING,ERROR,CRITICAL}]
                                                                   identifier [time_spec]

Telegram to Prompt Message Retriever (tg2p)

positional arguments:
  identifier            Username or alias of the contact
  time_spec             Time specification (e.g., 7d, 2w, 1m, 100, all)

options:
  -h, --help            show this help message and exit
  --tdl-path TDL_PATH   Path to tdl executable
  --contacts-dir CONTACTS_DIR
                        Directory containing contacts CSV files
  --raw-json-dir RAW_JSON_DIR
                        Directory for storing raw JSON files
  --markdown-dir MARKDOWN_DIR
                        Base directory for storing markdown files
  --log-level {DEBUG,INFO,WARNING,ERROR,CRITICAL}
                        Set logging level
```

## Модификаторы времени
- `d` - дни (например, 7d = 7 дней)
- `w` - недели (например, 2w = 2 недели)
- `m` - месяцы (например, 1m = 1 месяц)
- `y` - годы (например, 1y = 1 год)
- `h` - часы (например, 12h = 12 часов)
- без суффикса - количество сообщений (например, 100 = последние 100 сообщений)
- `all` - все сообщения

# Updates and Fixes

## 2025-04-15: Added Support for Groups and Channels
- [x] Fixed file naming convention for groups and channels:
  - Groups now use `group_id` instead of `tg_id` in filenames
  - For groups without usernames, the pattern is now `group_{chat_id}` instead of `user_{chat_id}`
- [x] Fixed conversion to markdown:
  - Removed unsupported parameters (`--usernameOverride`, `--firstNameOverride`) that were causing errors
  - Simplified command execution to work with all chat types
- [x] Improved archive function to handle both user and group filename patterns
- [x] These changes allow the script to work with:
  - Direct messages (one-on-one chats)
  - Group chats
  - Channels

## 2025-04-17: Added DayLastContacted Tracking
- [x] Added automatic updating of the "DayLastContacted" field in contact CSV files
- [x] The field is updated to the current date when messages are retrieved for a contact
- [x] This allows tracking of:
  - When a contact was last accessed through the tg2p tool
  - Frequency of interactions with specific contacts or groups
  - Historical data for contact activity analysis
- [x] The feature works with all CSV files that have the DayLastContacted column
- [x] Implementation details:
  - Added a new function `update_day_last_contacted` to handle CSV updates
  - Modified the `process_messages_for_contact` function to call the update function
  - Uses the current date (YYYY-MM-DD format) for the DayLastContacted field
  - Handles errors gracefully if CSV files are missing or malformed
  - Updates both the main contacts file and any namespace-specific files

## 2025-04-17: Added CSV File Format Support Improvements
- [x] Enhanced CSV file processing to handle different formats:
  - Standard format: `telegram-{namespace}-contacts-chats-list.csv`
  - Additional support for any CSV file with ID and DayLastContacted columns
- [x] Automatic detection of column layouts across different CSV formats
- [x] Improved error handling for malformed or incomplete CSV files
- [x] Added logging for CSV file operations to track updates