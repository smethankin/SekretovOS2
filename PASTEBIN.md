# SekretovOS — Pastebin: загрузка и установка одной командой

## Что нужно в игре

- **OpenOS** на компьютере
- **Internet Card** (иначе `pastebin get` не работает)
- Включён доступ к Pastebin в конфиге сервера (обычно по умолчанию разрешён)

---

## Шаг 1. Загрузить файлы на Pastebin (с ПК)

### Вариант A — вручную (проще всего)

1. Открой https://pastebin.com (аккаунт не обязателен, но удобнее).
2. Для **каждого** файла проекта:
   - **Create New Paste**
   - **Paste Name**: например `SekretovOS-main` (любое имя)
   - **Syntax Highlighting**: **Lua**
   - Вставь **полное содержимое** файла (без лишних строк в начале/конце)
   - **Paste Exposure**: **Public** (иначе OC может не скачать)
   - Нажми **Create New Paste**
3. В адресе будет код, например:  
   `https://pastebin.com/AbCdEf12` → код **`AbCdEf12`**
4. Запиши код в таблицу (блокнот):

| Файл | Pastebin code |
|------|----------------|
| main.lua | |
| system/kernel.lua | |
| … | |

5. Отдельно залей **`install.lua`** (уже с подставленными кодами из таблицы) — его код будет **`INSTALL_CODE`** для игроков.

### Вариант B — скрипт с API (много файлов)

1. Зарегистрируйся на Pastebin → **API** → скопируй **Developer API Key**.
2. В PowerShell из папки проекта:

```powershell
cd "C:\Users\Job\Desktop\SekretovOS"
$env:PASTEBIN_API_KEY = "твой_ключ_сюда"
.\tools\publish-pastebin.ps1
```

Скрипт выведет коды и обновит `install.lua` (если добавлен ключ).

---

## Шаг 2. Собрать install.lua

Открой `install.lua` и замени плейсхолдеры на реальные коды:

```lua
{ path = "main.lua", code = "AbCdEf12" },
{ path = "system/kernel.lua", code = "XyZ78901" },
-- ...
```

Залей **готовый** `install.lua` на Pastebin ещё раз → получишь **`INSTALL_CODE`**.

---

## Шаг 3. Одна команда в Minecraft (OpenComputers)

Игрок в терминале OC:

```lua
pastebin get INSTALL_CODE install && install
```

Пример (подставь свой код):

```lua
pastebin get a1b2c3d4 install && install
```

Что произойдёт:

1. Скачается `install.lua` в корень (как `install`).
2. Запустится установщик → создаст `/SekretovOS/...` и скачает все файлы из `MANIFEST`.
3. Автоматически запустится `main` (если `RUN_AFTER = true` в install.lua).

### Только установка, без автозапуска

В `install.lua` поставь:

```lua
local RUN_AFTER = false
```

Потом:

```lua
/SekretovOS/main
```

---

## Шаг 4. Команда для друзей / сервера

Дай одну строку в чат или на табличку:

```
pastebin get INSTALL_CODE install && install
```

Или алиас в OpenOS (`~/.aliases`):

```
alias sekretov="pastebin get INSTALL_CODE install && install"
```

---

## HTTP 403 Forbidden (частая проблема)

Pastebin **блокирует** стандартный `pastebin get` из OpenComputers (`/raw/` → 403).

### Решение A — скрипт с User-Agent

1. Скопируй `oc-download.lua` с флешки в компьютер (или набери через `edit`).
2. Выполни:

```lua
oc-download yVh06yQL sekretov
sekretov
```

### Решение B — вручную в Lua (без файла)

```lua
local internet = require("internet")
local f = io.open("sekretov","w")
for c in internet.request("https://pastebin.com/dl/yVh06yQL",8,{["User-Agent"]="Mozilla/5.0"}) do f:write(c) end
f:close()
loadfile("sekretov")()
```

### Решение C — флешка (без интернета)

Скопируй `sekretov-install.lua` в корень OC как `sekretov`, затем:

```lua
sekretov
```

### Решение D — настройки paste

- Exposure: **Public** (не Unlisted / Private)
- Создай **новый** paste и новый код

---

## Частые проблемы

| Проблема | Решение |
|----------|---------|
| `HTTP 403` | См. раздел выше; Public paste + `oc-download` или `/dl/` |
| `pastebin: failed` | Нет Internet Card или Pastebin отключён на сервере |
| `SKIP (not configured)` | В `install.lua` остались `PASTE_*` — вставь реальные коды |
| Файл пустой / ошибка Lua | При заливке скопировал не весь файл; залей заново |
| Слишком много запросов | Pastebin лимитирует API; подожди или залей с аккаунтом |

---

## Альтернатива без Pastebin

- Флешка / дискета: скопировать папку `SekretovOS` в `/SekretovOS`
- **wget** + GitHub raw (если есть `wget` и интернет):

```lua
wget https://raw.githubusercontent.com/USER/REPO/main/install.lua /install
install
```

---

## Минимальный набор для теста

Если не хочешь заливать всё сразу — залей минимум:

1. `install.lua` (с 2–3 кодами для теста)
2. `main.lua` + `system/kernel.lua` + `system/render.lua`

Остальные допиши в `MANIFEST` позже.
